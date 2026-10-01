import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/time_format.dart';
import '../../../theme/material_expressive.dart';

class MessageBubble extends StatelessWidget {
  final MessageItem message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final List<UserInfo> threadUsers;
  final void Function(String emoji) onReaction;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.threadUsers,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleTheme = theme.extension<ChatBubbleTheme>();
    final isSent = message.isSentByMe;

    final bubbleColor = isSent
        ? (bubbleTheme?.sentColor ?? theme.colorScheme.primary)
        : (bubbleTheme?.receivedColor ??
            theme.colorScheme.surfaceContainerHighest);
    final textColor = isSent
        ? (bubbleTheme?.sentTextColor ?? Colors.white)
        : (bubbleTheme?.receivedTextColor ?? theme.colorScheme.onSurface);

    // Bubble shape with directional corners
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isSent || !isFirstInGroup ? 20 : 4),
      topRight: Radius.circular(!isSent || !isFirstInGroup ? 20 : 4),
      bottomLeft: Radius.circular(isSent || !isLastInGroup ? 20 : 4),
      bottomRight: Radius.circular(!isSent || !isLastInGroup ? 20 : 4),
    );

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirstInGroup ? 8 : 2,
          bottom: isLastInGroup ? 4 : 0,
          left: isSent ? 64 : 0,
          right: isSent ? 0 : 64,
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message content
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media content
                  if (message.media != null) _buildMedia(context),

                  // Text content
                  if (message.text != null && message.text!.isNotEmpty)
                    Text(
                      message.text!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),

                  // Timestamp
                  if (isLastInGroup)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Reactions
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _buildReactions(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final media = message.media!;
    if (media.mediaType == 'image' || media.mediaType == 'video') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            media.thumbnailUrl ?? media.url,
            width: 240,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 240,
                height: 180,
                color: Colors.grey.withValues(alpha: 0.2),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 240,
              height: 120,
              color: Colors.grey.withValues(alpha: 0.2),
              child: const Icon(Icons.broken_image_rounded, size: 32),
            ),
          ),
        ),
      );
    }

    if (media.mediaType == 'audio') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, size: 20,
                color: message.isSentByMe ? Colors.white70 : Colors.grey),
            const SizedBox(width: 8),
            const Text('Voice message'),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildReactions(ThemeData theme) {
    // Group reactions by emoji
    final Map<String, int> emojiCounts = {};
    for (final r in message.reactions) {
      emojiCounts[r.emoji] = (emojiCounts[r.emoji] ?? 0) + 1;
    }

    return Wrap(
      spacing: 4,
      children: emojiCounts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  void _showReactionPicker(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReaction(emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
