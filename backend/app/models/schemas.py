"""
Pydantic schemas for API request/response models.
"""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


# ─── Auth ────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str
    verification_code: Optional[str] = None  # For 2FA


class LoginResponse(BaseModel):
    success: bool
    user_id: Optional[int] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    profile_pic_url: Optional[str] = None
    message: Optional[str] = None
    requires_2fa: bool = False
    # Instagram sent an email/SMS challenge — user must enter the code
    requires_challenge: bool = False


class SessionStatus(BaseModel):
    logged_in: bool
    user_id: Optional[int] = None
    username: Optional[str] = None


# ─── User ────────────────────────────────────────────────────────────────────

class UserInfo(BaseModel):
    pk: int
    username: str
    full_name: str
    profile_pic_url: Optional[str] = None
    is_verified: bool = False
    is_private: bool = False


# ─── Thread / Inbox ─────────────────────────────────────────────────────────

class ThreadItem(BaseModel):
    thread_id: str
    thread_title: str
    users: list[UserInfo]
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    is_group: bool = False
    unread_count: int = 0
    muted: bool = False
    thread_image_url: Optional[str] = None


class InboxResponse(BaseModel):
    threads: list[ThreadItem]
    has_older: bool = False
    cursor: Optional[str] = None
    pending_count: int = 0


# ─── Messages ────────────────────────────────────────────────────────────────

class MessageType(str, Enum):
    TEXT = "text"
    MEDIA = "media"
    VOICE = "voice"
    REEL_SHARE = "reel_share"
    STORY_SHARE = "story_share"
    LINK = "link"
    LIKE = "like"
    REACTION = "reaction"
    ANIMATED_MEDIA = "animated_media"
    CLIP = "clip"
    PROFILE = "profile"
    PLACEHOLDER = "placeholder"
    ACTION_LOG = "action_log"
    UNKNOWN = "unknown"


class Reaction(BaseModel):
    emoji: str
    user_id: int
    username: Optional[str] = None
    timestamp: Optional[datetime] = None


class MediaInfo(BaseModel):
    url: str
    media_type: str  # "image", "video", "audio"
    width: Optional[int] = None
    height: Optional[int] = None
    thumbnail_url: Optional[str] = None


class MessageItem(BaseModel):
    message_id: str
    user_id: int
    username: Optional[str] = None
    timestamp: datetime
    message_type: MessageType
    text: Optional[str] = None
    media: Optional[MediaInfo] = None
    reactions: list[Reaction] = Field(default_factory=list)
    reply_to_message_id: Optional[str] = None
    is_sent_by_me: bool = False
    seen_by: list[int] = Field(default_factory=list)


class ThreadMessagesResponse(BaseModel):
    thread_id: str
    messages: list[MessageItem]
    has_older: bool = False
    cursor: Optional[str] = None
    users: list[UserInfo] = Field(default_factory=list)
    # user_pk (str) → ISO-8601 datetime of the last message they have seen
    seen_at: dict[str, str] = Field(default_factory=dict)


# ─── Send Message ────────────────────────────────────────────────────────────

class SendTextRequest(BaseModel):
    thread_id: str
    text: str
    reply_to_message_id: Optional[str] = None


class SendMediaRequest(BaseModel):
    thread_id: str
    media_type: str  # "image", "video", "voice"


class ReactionRequest(BaseModel):
    thread_id: str
    message_id: str
    emoji: str  # e.g., "❤️", "😂", "😮", "😢", "😡", "👍"


class SendMessageResponse(BaseModel):
    success: bool
    message_id: Optional[str] = None
    message: Optional[str] = None


# ─── Search ──────────────────────────────────────────────────────────────────

class SearchUsersRequest(BaseModel):
    query: str
    limit: int = 20


class SearchUsersResponse(BaseModel):
    users: list[UserInfo]


# ─── WebSocket Events ───────────────────────────────────────────────────────

class WSEventType(str, Enum):
    NEW_MESSAGE = "new_message"
    MESSAGE_SEEN = "message_seen"
    TYPING = "typing"
    THREAD_UPDATE = "thread_update"
    REACTION = "reaction"
    ERROR = "error"


class WSEvent(BaseModel):
    event: WSEventType
    data: dict
    timestamp: datetime = Field(default_factory=datetime.utcnow)
