import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ThreadItem thread;

  const ChatScreen({super.key, required this.thread});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(messagesProvider(widget.thread.threadId).notifier).fetchMessages();
    });

    // Fallback poll every 30 s (WebSocket handles real-time updates;
    // this catches anything missed if the WS drops temporarily).
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref
            .read(messagesProvider(widget.thread.threadId).notifier)
            .refreshMessages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleSend(String text) async {
    await ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .sendText(text);
    _scrollToBottom();
  }

  Future<void> _handleSendPhoto(File photo) async {
    await ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .sendPhoto(photo);
    _scrollToBottom();
  }

  Future<void> _handleSendVideo(File video) async {
    await ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .sendVideo(video);
    _scrollToBottom();
  }

  Future<void> _handleSendVoice(File audio) async {
    await ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .sendVoice(audio);
    _scrollToBottom();
  }

  void _handleReaction(String messageId, String emoji) {
    ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .reactToMessage(messageId, emoji);
  }

  void _handleUnreact(String messageId, String emoji) {
    ref
        .read(messagesProvider(widget.thread.threadId).notifier)
        .unreactToMessage(messageId, emoji);
  }

  @override
  Widget build(BuildContext context) {
    final messagesState =
        ref.watch(messagesProvider(widget.thread.threadId));
    final currentUserId = ref.watch(authProvider).userId;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Show a snackbar whenever a send error occurs
    ref.listen<MessagesState>(
      messagesProvider(widget.thread.threadId),
      (prev, next) {
        if (next.error != null && next.error != prev?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: cs.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              backgroundImage: widget.thread.threadImageUrl != null
                  ? NetworkImage(widget.thread.threadImageUrl!)
                  : (widget.thread.users.isNotEmpty &&
                          widget.thread.users.first.profilePicUrl != null
                      ? NetworkImage(
                          widget.thread.users.first.profilePicUrl!)
                      : null),
              child: widget.thread.threadImageUrl == null &&
                      (widget.thread.users.isEmpty ||
                          widget.thread.users.first.profilePicUrl == null)
                  ? Icon(Icons.person, size: 18, color: cs.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.thread.threadTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.thread.isGroup &&
                      widget.thread.users.isNotEmpty)
                    Text(
                      '@${widget.thread.users.first.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessages(messagesState, theme, currentUserId),
          ),

          // Input bar
          ChatInput(
            onSend: _handleSend,
            onSendPhoto: _handleSendPhoto,
            onSendVideo: _handleSendVideo,
            onSendVoice: _handleSendVoice,
            isSending: messagesState.isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(MessagesState state, ThemeData theme, int? currentUserId) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newest messages at bottom
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final prevMessage =
            index < state.messages.length - 1 ? state.messages[index + 1] : null;
        final nextMessage = index > 0 ? state.messages[index - 1] : null;

        // Show date separator if different day
        final showDateSeparator = prevMessage == null ||
            !_isSameDay(message.timestamp, prevMessage.timestamp);

        // Group consecutive messages from same sender
        final isFirstInGroup = prevMessage == null ||
            prevMessage.userId != message.userId ||
            message.timestamp.difference(prevMessage.timestamp).inMinutes > 5;
        final isLastInGroup = nextMessage == null ||
            nextMessage.userId != message.userId ||
            nextMessage.timestamp.difference(message.timestamp).inMinutes > 5;

        return Column(
          children: [
            if (showDateSeparator)
              _buildDateSeparator(message.timestamp, theme),
            MessageBubble(
              message: message,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              threadUsers: widget.thread.users,
              currentUserId: currentUserId,
              onReaction: (emoji) =>
                  _handleReaction(message.messageId, emoji),
              onUnreact: (emoji) =>
                  _handleUnreact(message.messageId, emoji),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(messageDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
