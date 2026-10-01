/// Inbox & Messages providers using Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ─── Inbox Provider ─────────────────────────────────────────────────────────

class InboxState {
  final List<ThreadItem> threads;
  final bool isLoading;
  final String? error;

  const InboxState({
    this.threads = const [],
    this.isLoading = false,
    this.error,
  });

  InboxState copyWith({
    List<ThreadItem>? threads,
    bool? isLoading,
    String? error,
  }) {
    return InboxState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final ApiClient _api;

  InboxNotifier(this._api) : super(const InboxState());

  Future<void> fetchInbox() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final threads = await _api.getInbox();
      state = InboxState(threads: threads);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load inbox: $e',
      );
    }
  }

  Future<void> refreshInbox() async {
    try {
      final threads = await _api.getInbox();
      state = InboxState(threads: threads);
    } catch (e) {
      state = state.copyWith(error: 'Refresh failed: $e');
    }
  }
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final api = ref.watch(apiClientProvider);
  return InboxNotifier(api);
});

// ─── Messages Provider ──────────────────────────────────────────────────────

class MessagesState {
  final String threadId;
  final List<MessageItem> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const MessagesState({
    required this.threadId,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  MessagesState copyWith({
    List<MessageItem>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return MessagesState(
      threadId: threadId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiClient _api;

  MessagesNotifier(this._api, String threadId)
      : super(MessagesState(threadId: threadId));

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _api.getMessages(state.threadId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  Future<void> sendText(String text) async {
    state = state.copyWith(isSending: true);
    try {
      await _api.sendText(state.threadId, text);
      // Refresh messages after sending
      await fetchMessages();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send: $e',
      );
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      await _api.reactToMessage(state.threadId, messageId, emoji);
      await fetchMessages();
    } catch (e) {
      state = state.copyWith(error: 'Failed to react: $e');
    }
  }

  Future<void> refreshMessages() async {
    try {
      final messages = await _api.getMessages(state.threadId);
      state = state.copyWith(messages: messages);
    } catch (_) {}
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    MessagesState, String>((ref, threadId) {
  final api = ref.watch(apiClientProvider);
  return MessagesNotifier(api, threadId);
});
