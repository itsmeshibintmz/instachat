/// Inbox & Messages providers using Riverpod
library;

import 'dart:io';

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
  final bool isLoadingMore;   // fetching older messages
  final bool isSending;
  final bool hasOlder;        // more messages available above
  final String? cursor;       // pagination cursor for next older page
  /// user-pk (string) → last datetime that user acknowledged messages.
  /// Used to show "Seen" under the appropriate sent message.
  final Map<String, DateTime> seenAt;
  final String? error;

  const MessagesState({
    required this.threadId,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.hasOlder = false,
    this.cursor,
    this.seenAt = const {},
    this.error,
  });

  MessagesState copyWith({
    List<MessageItem>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? hasOlder,
    String? cursor,
    Map<String, DateTime>? seenAt,
    String? error,
  }) {
    return MessagesState(
      threadId: threadId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      hasOlder: hasOlder ?? this.hasOlder,
      cursor: cursor ?? this.cursor,
      seenAt: seenAt ?? this.seenAt,
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
      final page = await _api.getMessages(state.threadId);
      state = state.copyWith(
        messages: page.messages,
        hasOlder: page.hasOlder,
        cursor: page.cursor,
        seenAt: page.seenAt,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  /// Tells Instagram that the current user has seen all messages in this thread.
  Future<void> markAsSeen() async {
    try {
      await _api.markSeen(state.threadId);
    } catch (_) {
      // Non-fatal — silently ignore
    }
  }

  /// Loads the next page of older messages and prepends them to the list.
  Future<void> loadOlderMessages() async {
    if (!state.hasOlder || state.isLoadingMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await _api.getMessages(
        state.threadId,
        cursor: state.cursor,
      );
      // Append older messages (they come after the existing ones since list is
      // reverse-sorted newest-first; older messages go at the end).
      final combined = [...state.messages, ...page.messages];
      state = state.copyWith(
        messages: combined,
        hasOlder: page.hasOlder,
        cursor: page.cursor,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load older messages: $e',
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

  Future<void> sendPhoto(File photo) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _api.sendPhoto(state.threadId, photo);
      await fetchMessages();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send photo: $e',
      );
    }
  }

  Future<void> sendVideo(File video) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _api.sendVideo(state.threadId, video);
      await fetchMessages();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send video: $e',
      );
    }
  }

  Future<void> sendVoice(File audio) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _api.sendVoice(state.threadId, audio);
      await fetchMessages();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send voice message: $e',
      );
    }
  }

  Future<void> unreactToMessage(String messageId, String emoji) async {
    try {
      await _api.unreactToMessage(state.threadId, messageId, emoji);
      await fetchMessages();
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove reaction: $e');
    }
  }

  Future<void> refreshMessages() async {
    try {
      final page = await _api.getMessages(state.threadId);
      state = state.copyWith(
        messages: page.messages,
        hasOlder: page.hasOlder,
        cursor: page.cursor,
        seenAt: page.seenAt,
      );
    } catch (_) {}
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    MessagesState, String>((ref, threadId) {
  final api = ref.watch(apiClientProvider);
  return MessagesNotifier(api, threadId);
});
