import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/time_format.dart';

class ThreadTile extends StatelessWidget {
  final ThreadItem thread;
  final VoidCallback onTap;

  const ThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasUnread = thread.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(cs),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.threadTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (thread.lastMessageAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatTimeAgo(thread.lastMessageAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.4),
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage ?? 'Tap to view conversation',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasUnread
                                ? cs.onSurface.withValues(alpha: 0.8)
                                : cs.onSurface.withValues(alpha: 0.45),
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            thread.unreadCount > 99
                                ? '99+'
                                : '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (thread.muted)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    final imageUrl = thread.threadImageUrl ??
        (thread.users.isNotEmpty ? thread.users.first.profilePicUrl : null);

    if (thread.isGroup && thread.users.length > 1) {
      // Group avatar: stacked circles
      return SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: _circleAvatar(
                thread.users.length > 1
                    ? thread.users[1].profilePicUrl
                    : null,
                32,
                cs,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: _circleAvatar(
                  thread.users.isNotEmpty
                      ? thread.users[0].profilePicUrl
                      : null,
                  32,
                  cs,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _circleAvatar(imageUrl, 52, cs);
  }

  Widget _circleAvatar(String? imageUrl, double size, ColorScheme cs) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary.withValues(alpha: 0.12),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Icon(Icons.person, size: size * 0.5, color: cs.primary)
          : null,
    );
  }
}
