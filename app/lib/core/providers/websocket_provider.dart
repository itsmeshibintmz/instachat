/// WebSocket provider — manages the persistent WS connection to the backend.
///
/// Connects after login, auto-reconnects on drop (5 s back-off),
/// and dispatches inbox / message refreshes when events arrive.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_provider.dart'; // for apiClientProvider
import 'chat_providers.dart'; // for inboxProvider, messagesProvider

// ─── State ───────────────────────────────────────────────────────────────────

enum WsStatus { disconnected, connecting, connected, error }

class WebSocketState {
  final WsStatus status;
  final String? error;

  const WebSocketState({
    this.status = WsStatus.disconnected,
    this.error,
  });

  WebSocketState copyWith({WsStatus? status, String? error}) {
    return WebSocketState(
      status: status ?? this.status,
      error: error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final ApiClient _api;
  final Ref _ref;

  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _shouldBeConnected = false;

  WebSocketNotifier(this._api, this._ref) : super(const WebSocketState());

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call after a successful login.
  void connect() {
    _shouldBeConnected = true;
    _doConnect();
  }

  /// Call after logout or when the app is backgrounded for a long time.
  void disconnect() {
    _shouldBeConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _api.disconnectWebSocket();
    if (mounted) state = const WebSocketState();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _doConnect() {
    if (!mounted) return;
    if (state.status == WsStatus.connecting ||
        state.status == WsStatus.connected) return;

    state = state.copyWith(status: WsStatus.connecting, error: null);

    try {
      final channel = _api.connectWebSocket();
      if (!mounted) return;
      state = state.copyWith(status: WsStatus.connected);

      _subscription?.cancel();
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object error) {
          if (!mounted) return;
          state = state.copyWith(
            status: WsStatus.error,
            error: error.toString(),
          );
          _scheduleReconnect();
        },
        onDone: () {
          if (!mounted || !_shouldBeConnected) return;
          state = state.copyWith(status: WsStatus.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: WsStatus.error,
        error: e.toString(),
      );
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    if (!mounted) return;
    try {
      final event = jsonDecode(data as String) as Map<String, dynamic>;

      // Backend field is "event", not "type"
      final eventType = event['event'] as String?;
      final eventData = event['data'] as Map<String, dynamic>?;

      switch (eventType) {
        case 'new_message':
          // Refresh the specific thread + inbox unread counts
          final threadId = eventData?['thread_id'] as String?;
          if (threadId != null) {
            _ref
                .read(messagesProvider(threadId).notifier)
                .refreshMessages();
          }
          _ref.read(inboxProvider.notifier).refreshInbox();
          break;

        case 'thread_update':
          // New message detected by polling — refresh inbox + that thread
          final threadId = eventData?['thread_id'] as String?;
          if (threadId != null) {
            _ref
                .read(messagesProvider(threadId).notifier)
                .refreshMessages();
          }
          _ref.read(inboxProvider.notifier).refreshInbox();
          break;

        case 'reaction':
          // Reaction added/removed — refresh that thread's messages
          final threadId = eventData?['thread_id'] as String?;
          if (threadId != null) {
            _ref
                .read(messagesProvider(threadId).notifier)
                .refreshMessages();
          }
          break;

        case 'typing':
          // Phase 3 — typing indicators, not wired to UI yet
          break;

        case 'message_seen':
          // Phase 3 — read receipts, ignore for now
          break;
      }
    } catch (_) {
      // Malformed / unexpected event — silently ignore
    }
  }

  void _scheduleReconnect() {
    if (!_shouldBeConnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldBeConnected && mounted) _doConnect();
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final wsProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  final api = ref.watch(apiClientProvider);
  return WebSocketNotifier(api, ref);
});
