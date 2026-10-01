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
  final int? currentUserId;
  final void Function(String emoji) onReaction;
  final void Function(String emoji)? onUnreact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.threadUsers,
    required this.onReaction,
    this.currentUserId,
    this.onUnreact,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Emojis the current user has already reacted with on this message.
  Set<String> get _myReactions => {
        for (final r in message.reactions)
          if (r.userId == currentUserId) r.emoji,
      };

  void _toggleReaction(String emoji) {
    if (_myReactions.contains(emoji)) {
      onUnreact?.call(emoji);
    } else {
      onReaction(emoji);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            // Bubble
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.media != null) _buildMedia(context),
                  if (message.text != null && message.text!.isNotEmpty)
                    Text(
                      message.text!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
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

            // Reaction chips — tappable to toggle
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildReactionChips(theme),
              ),
          ],
        ),
      ),
    );
  }

  // ── Reaction chips ─────────────────────────────────────────────────────────

  Widget _buildReactionChips(ThemeData theme) {
    final cs = theme.colorScheme;
    final myReacted = _myReactions;

    // Aggregate: emoji → count
    final Map<String, int> counts = {};
    for (final r in message.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: counts.entries.map((entry) {
        final isMine = myReacted.contains(entry.key);
        return GestureDetector(
          onTap: () => _toggleReaction(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isMine
                  ? cs.primary.withValues(alpha: 0.15)
                  : cs.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMine
                    ? cs.primary.withValues(alpha: 0.5)
                    : cs.onSurface.withValues(alpha: 0.1),
                width: isMine ? 1.5 : 1,
              ),
            ),
            child: Text(
              entry.value > 1
                  ? '${entry.key} ${entry.value}'
                  : entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Media ──────────────────────────────────────────────────────────────────

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
              child:
                  const Icon(Icons.broken_image_rounded, size: 32),
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
            Icon(Icons.mic_rounded,
                size: 20,
                color: message.isSentByMe
                    ? Colors.white70
                    : Colors.grey),
            const SizedBox(width: 8),
            const Text('Voice message'),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Reaction picker ────────────────────────────────────────────────────────

  void _showReactionPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    final myReacted = _myReactions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Emoji row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '😡', '👍']
                    .map((emoji) {
                  final alreadyReacted = myReacted.contains(emoji);
                  return _ReactionButton(
                    emoji: emoji,
                    isSelected: alreadyReacted,
                    onTap: () {
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                      _toggleReaction(emoji);
                    },
                  );
                }).toList(),
              ),
              if (myReacted.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Tap your reaction to remove it',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Animated reaction button ───────────────────────────────────────────────

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _ctrl.reverse();
    await _ctrl.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSelected
                ? cs.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: widget.isSelected
                ? Border.all(
                    color: cs.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.emoji,
            style: TextStyle(
              fontSize: widget.isSelected ? 30 : 28,
            ),
          ),
        ),
      ),
    );
  }
}
