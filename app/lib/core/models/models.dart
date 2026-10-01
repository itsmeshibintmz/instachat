/// Data models for the InstaChat Flutter app.
/// These mirror the backend Pydantic schemas.
library;

class UserInfo {
  final int pk;
  final String username;
  final String fullName;
  final String? profilePicUrl;
  final bool isVerified;
  final bool isPrivate;

  const UserInfo({
    required this.pk,
    required this.username,
    required this.fullName,
    this.profilePicUrl,
    this.isVerified = false,
    this.isPrivate = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      pk: json['pk'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? json['username'] as String,
      profilePicUrl: json['profile_pic_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
    );
  }
}

class ThreadItem {
  final String threadId;
  final String threadTitle;
  final List<UserInfo> users;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isGroup;
  final int unreadCount;
  final bool muted;
  final String? threadImageUrl;

  const ThreadItem({
    required this.threadId,
    required this.threadTitle,
    required this.users,
    this.lastMessage,
    this.lastMessageAt,
    this.isGroup = false,
    this.unreadCount = 0,
    this.muted = false,
    this.threadImageUrl,
  });

  factory ThreadItem.fromJson(Map<String, dynamic> json) {
    return ThreadItem(
      threadId: json['thread_id'] as String,
      threadTitle: json['thread_title'] as String,
      users: (json['users'] as List<dynamic>)
          .map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      isGroup: json['is_group'] as bool? ?? false,
      unreadCount: json['unread_count'] as int? ?? 0,
      muted: json['muted'] as bool? ?? false,
      threadImageUrl: json['thread_image_url'] as String?,
    );
  }
}

enum MessageType {
  text,
  media,
  voice,
  reelShare,
  storyShare,
  link,
  like,
  reaction,
  animatedMedia,
  clip,
  profile,
  placeholder,
  actionLog,
  unknown;

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'media':
        return MessageType.media;
      case 'voice':
        return MessageType.voice;
      case 'reel_share':
        return MessageType.reelShare;
      case 'story_share':
        return MessageType.storyShare;
      case 'link':
        return MessageType.link;
      case 'like':
        return MessageType.like;
      case 'reaction':
        return MessageType.reaction;
      case 'animated_media':
        return MessageType.animatedMedia;
      case 'clip':
        return MessageType.clip;
      case 'profile':
        return MessageType.profile;
      case 'placeholder':
        return MessageType.placeholder;
      case 'action_log':
        return MessageType.actionLog;
      default:
        return MessageType.unknown;
    }
  }
}

class MediaInfo {
  final String url;
  final String mediaType;
  final int? width;
  final int? height;
  final String? thumbnailUrl;

  const MediaInfo({
    required this.url,
    required this.mediaType,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      url: json['url'] as String,
      mediaType: json['media_type'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

class Reaction {
  final String emoji;
  final int userId;
  final String? username;

  const Reaction({
    required this.emoji,
    required this.userId,
    this.username,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      emoji: json['emoji'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String?,
    );
  }
}

/// Wraps a paginated messages response from the backend.
class MessagesPage {
  final List<MessageItem> messages;
  final bool hasOlder;
  final String? cursor;
  final List<UserInfo> users;
  /// user-pk (string) → last datetime that user read a message in this thread.
  /// Only contains entries for OTHER participants (not the logged-in user).
  final Map<String, DateTime> seenAt;

  const MessagesPage({
    required this.messages,
    required this.hasOlder,
    this.cursor,
    required this.users,
    this.seenAt = const {},
  });

  factory MessagesPage.fromJson(Map<String, dynamic> json) {
    // Parse seen_at: { "12345": "2026-10-01T04:00:00.000Z", ... }
    final rawSeenAt = json['seen_at'] as Map<String, dynamic>? ?? {};
    final seenAt = <String, DateTime>{};
    rawSeenAt.forEach((k, v) {
      if (v is String) {
        try {
          seenAt[k] = DateTime.parse(v);
        } catch (_) {}
      }
    });

    return MessagesPage(
      messages: (json['messages'] as List<dynamic>)
          .map((m) => MessageItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      hasOlder: json['has_older'] as bool? ?? false,
      cursor: json['cursor'] as String?,
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      seenAt: seenAt,
    );
  }
}

class MessageItem {
  final String messageId;
  final int userId;
  final String? username;
  final DateTime timestamp;
  final MessageType messageType;
  final String? text;
  final MediaInfo? media;
  final List<Reaction> reactions;
  final String? replyToMessageId;
  final bool isSentByMe;

  const MessageItem({
    required this.messageId,
    required this.userId,
    this.username,
    required this.timestamp,
    required this.messageType,
    this.text,
    this.media,
    this.reactions = const [],
    this.replyToMessageId,
    this.isSentByMe = false,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      messageId: json['message_id'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageType: MessageType.fromString(json['message_type'] as String),
      text: json['text'] as String?,
      media: json['media'] != null
          ? MediaInfo.fromJson(json['media'] as Map<String, dynamic>)
          : null,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => Reaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      replyToMessageId: json['reply_to_message_id'] as String?,
      isSentByMe: json['is_sent_by_me'] as bool? ?? false,
    );
  }
}
