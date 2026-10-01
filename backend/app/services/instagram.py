"""
Instagram Client Service — wraps instagrapi for InstaChat.

Handles authentication, session persistence, inbox fetching,
message retrieval, sending, reactions, and media.
"""
from __future__ import annotations

import json
import logging
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from instagrapi import Client
from instagrapi.exceptions import (
    BadPassword,
    ChallengeRequired,
    LoginRequired,
    TwoFactorRequired,
    PleaseWaitFewMinutes,
    ClientError,
)
from instagrapi.types import DirectThread, DirectMessage, UserShort

from app.config import SESSION_DIR, MAX_MESSAGES_PER_FETCH
from app.models.schemas import (
    LoginResponse,
    UserInfo,
    ThreadItem,
    InboxResponse,
    MessageItem,
    MessageType,
    MediaInfo,
    Reaction,
    ThreadMessagesResponse,
    SendMessageResponse,
)

logger = logging.getLogger("instachat.instagram")


class InstagramService:
    """Singleton-style Instagram client wrapper."""

    def __init__(self):
        self._client: Optional[Client] = None
        self._user_id: Optional[int] = None
        self._username: Optional[str] = None
        self._logged_in: bool = False
        self._session_file: Optional[Path] = None

    @property
    def is_logged_in(self) -> bool:
        return self._logged_in and self._client is not None

    @property
    def user_id(self) -> Optional[int]:
        return self._user_id

    @property
    def username(self) -> Optional[str]:
        return self._username

    # ─── Authentication ──────────────────────────────────────────────────

    def login(self, username: str, password: str, verification_code: Optional[str] = None) -> LoginResponse:
        """Login to Instagram with optional 2FA code."""
        self._client = Client()
        # Keep a small delay to avoid triggering Instagram's rate limiter,
        # but don't add unnecessary seconds to every sub-request.
        self._client.delay_range = [0, 1]
        # Tell instagrapi's internal HTTP client to give up after 30 s per
        # sub-request rather than hanging indefinitely.
        self._client.request_timeout = 30
        self._session_file = SESSION_DIR / f"{username}_session.json"

        # Try to reuse existing session
        if self._session_file.exists():
            try:
                self._client.load_settings(self._session_file)
                self._client.login(username, password)
                self._finalize_login(username)
                logger.info(f"Logged in via saved session: {username}")
                return self._build_login_response(success=True)
            except Exception as e:
                logger.warning(f"Session reuse failed: {e}, trying fresh login")
                self._client = Client()
                self._client.delay_range = [1, 3]

        # Fresh login
        try:
            if verification_code:
                self._client.login(username, password, verification_code=verification_code)
            else:
                self._client.login(username, password)

            self._finalize_login(username)
            self._save_session()
            logger.info(f"Fresh login successful: {username}")
            return self._build_login_response(success=True)

        except TwoFactorRequired:
            logger.info(f"2FA required for {username}")
            return LoginResponse(
                success=False,
                requires_2fa=True,
                message="Two-factor authentication required. Please provide the verification code.",
            )
        except BadPassword:
            return LoginResponse(success=False, message="Invalid password.")
        except ChallengeRequired:
            return LoginResponse(
                success=False,
                message="Instagram challenge required. Please open Instagram app, complete the challenge, then try again.",
            )
        except PleaseWaitFewMinutes:
            return LoginResponse(
                success=False,
                message="Too many login attempts. Please wait a few minutes and try again.",
            )
        except Exception as e:
            logger.error(f"Login failed: {e}")
            return LoginResponse(success=False, message=f"Login failed: {str(e)}")

    def logout(self):
        """Logout and clear session."""
        if self._client:
            try:
                self._client.logout()
            except Exception:
                pass
        self._client = None
        self._logged_in = False
        self._user_id = None
        self._username = None
        if self._session_file and self._session_file.exists():
            self._session_file.unlink()

    def _finalize_login(self, username: str):
        """Set internal state after successful login."""
        self._user_id = self._client.user_id
        self._username = username
        self._logged_in = True

    def _save_session(self):
        """Persist session to disk."""
        if self._client and self._session_file:
            self._client.dump_settings(self._session_file)

    def _build_login_response(self, success: bool) -> LoginResponse:
        """Build a LoginResponse with current user info."""
        try:
            user_info = self._client.user_info(self._user_id)
            return LoginResponse(
                success=success,
                user_id=self._user_id,
                username=self._username,
                full_name=user_info.full_name,
                profile_pic_url=str(user_info.profile_pic_url) if user_info.profile_pic_url else None,
            )
        except Exception:
            return LoginResponse(
                success=success,
                user_id=self._user_id,
                username=self._username,
            )

    def _ensure_logged_in(self):
        """Raise if not logged in."""
        if not self.is_logged_in:
            raise LoginRequired("Not logged in. Please login first.")

    # ─── Inbox ───────────────────────────────────────────────────────────

    def get_inbox(self, cursor: Optional[str] = None, limit: int = 20) -> InboxResponse:
        """Fetch inbox threads (conversations)."""
        self._ensure_logged_in()

        try:
            threads = self._client.direct_threads(amount=limit, selected_filter="unread") if cursor is None else self._client.direct_threads(amount=limit)

            # Also get pending count
            pending_count = 0
            try:
                pending_threads = self._client.direct_pending_inbox()
                pending_count = len(pending_threads) if pending_threads else 0
            except Exception:
                pass

            thread_items = []
            for thread in threads:
                thread_items.append(self._convert_thread(thread))

            return InboxResponse(
                threads=thread_items,
                has_older=len(threads) >= limit,
                pending_count=pending_count,
            )
        except Exception as e:
            logger.error(f"Failed to fetch inbox: {e}")
            raise

    def get_pending_inbox(self) -> InboxResponse:
        """Fetch pending message requests."""
        self._ensure_logged_in()
        try:
            threads = self._client.direct_pending_inbox()
            thread_items = [self._convert_thread(t) for t in (threads or [])]
            return InboxResponse(threads=thread_items)
        except Exception as e:
            logger.error(f"Failed to fetch pending inbox: {e}")
            raise

    # ─── Messages ────────────────────────────────────────────────────────

    def get_thread_messages(
        self, thread_id: str, cursor: Optional[str] = None, limit: int = MAX_MESSAGES_PER_FETCH
    ) -> ThreadMessagesResponse:
        """Fetch messages from a specific thread, with optional cursor for older messages."""
        self._ensure_logged_in()

        try:
            # Pass cursor to instagrapi so it fetches the correct page of messages
            thread = self._client.direct_thread(
                thread_id, amount=limit, cursor=cursor
            ) if cursor else self._client.direct_thread(thread_id, amount=limit)

            messages = []
            users_map: dict[int, UserInfo] = {}

            # Build users map
            for user in thread.users:
                users_map[user.pk] = self._convert_user(user)

            # Convert messages
            for msg in thread.messages:
                messages.append(self._convert_message(msg))

            # Extract the pagination cursor from the thread (instagrapi stores it after fetch)
            next_cursor = getattr(thread, 'cursor', None)

            # Build seen_at: for each OTHER participant, record when they last
            # saw a message so Flutter can show read receipts.
            seen_at: dict[str, str] = {}
            try:
                raw_seen = getattr(thread, 'last_seen_at', None) or {}
                for user_pk, seen_info in raw_seen.items():
                    if int(user_pk) == self._user_id:
                        continue  # skip our own entry
                    ts_str = getattr(seen_info, 'timestamp', None)
                    if ts_str:
                        # instagrapi gives timestamp in microseconds as a string
                        ts_us = int(ts_str)
                        dt = datetime.fromtimestamp(ts_us / 1_000_000, tz=timezone.utc)
                        seen_at[str(user_pk)] = dt.isoformat()
            except Exception as ex:
                logger.warning(f"Failed to extract last_seen_at: {ex}")

            return ThreadMessagesResponse(
                thread_id=thread_id,
                messages=messages,
                has_older=next_cursor is not None and len(messages) >= limit,
                cursor=next_cursor,
                users=list(users_map.values()),
                seen_at=seen_at,
            )
        except Exception as e:
            logger.error(f"Failed to fetch messages for thread {thread_id}: {e}")
            raise

    def send_text(self, thread_id: str, text: str, reply_to_message_id: Optional[str] = None) -> SendMessageResponse:
        """Send a text message to a thread."""
        self._ensure_logged_in()
        try:
            # Convert thread_id to int for direct_send
            thread_ids = [int(thread_id)]
            result = self._client.direct_send(text, thread_ids=thread_ids)
            return SendMessageResponse(
                success=True,
                message_id=result.id if result else None,
            )
        except Exception as e:
            logger.error(f"Failed to send text: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def send_photo(self, thread_id: str, photo_path: str) -> SendMessageResponse:
        """Send a photo to a thread."""
        self._ensure_logged_in()
        try:
            result = self._client.direct_send_photo(
                Path(photo_path), thread_ids=[int(thread_id)]
            )
            return SendMessageResponse(
                success=True,
                message_id=result.id if result else None,
            )
        except Exception as e:
            logger.error(f"Failed to send photo: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def send_video(self, thread_id: str, video_path: str) -> SendMessageResponse:
        """Send a video to a thread."""
        self._ensure_logged_in()
        try:
            result = self._client.direct_send_video(
                Path(video_path), thread_ids=[int(thread_id)]
            )
            return SendMessageResponse(
                success=True,
                message_id=result.id if result else None,
            )
        except Exception as e:
            logger.error(f"Failed to send video: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def send_voice(self, thread_id: str, audio_path: str) -> SendMessageResponse:
        """Send a voice message to a thread."""
        self._ensure_logged_in()
        try:
            result = self._client.direct_send_voice(
                Path(audio_path), thread_ids=[int(thread_id)]
            )
            return SendMessageResponse(
                success=True,
                message_id=result.id if result else None,
            )
        except Exception as e:
            logger.error(f"Failed to send voice: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def react_to_message(self, thread_id: str, message_id: str, emoji: str) -> SendMessageResponse:
        """React to a message with an emoji."""
        self._ensure_logged_in()
        try:
            # instagrapi uses item_id for reactions
            self._client.direct_send_reaction(
                emoji=emoji,
                item_id=message_id,
            )
            return SendMessageResponse(success=True)
        except Exception as e:
            logger.error(f"Failed to react: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def unreact_to_message(self, thread_id: str, message_id: str) -> SendMessageResponse:
        """Remove reaction from a message."""
        self._ensure_logged_in()
        try:
            self._client.direct_send_reaction(
                emoji="",
                item_id=message_id,
            )
            return SendMessageResponse(success=True)
        except Exception as e:
            logger.error(f"Failed to unreact: {e}")
            return SendMessageResponse(success=False, message=str(e))

    def mark_seen(self, thread_id: str, message_id: str) -> bool:
        """Mark a message as seen."""
        self._ensure_logged_in()
        try:
            self._client.direct_send_seen(int(thread_id))
            return True
        except Exception as e:
            logger.error(f"Failed to mark seen: {e}")
            return False

    # ─── User Search ─────────────────────────────────────────────────────

    def search_users(self, query: str, limit: int = 20) -> list[UserInfo]:
        """Search for Instagram users."""
        self._ensure_logged_in()
        try:
            users = self._client.search_users(query, amount=limit)
            return [self._convert_user(u) for u in users]
        except Exception as e:
            logger.error(f"Failed to search users: {e}")
            return []

    def create_thread(self, user_ids: list[int], message: str = "") -> Optional[str]:
        """Create a new DM thread with one or more users."""
        self._ensure_logged_in()
        try:
            result = self._client.direct_send(message or "👋", user_ids=user_ids)
            return result.thread_id if result else None
        except Exception as e:
            logger.error(f"Failed to create thread: {e}")
            return None

    # ─── Converters ──────────────────────────────────────────────────────

    def _convert_thread(self, thread: DirectThread) -> ThreadItem:
        """Convert instagrapi DirectThread to our ThreadItem schema."""
        users = [self._convert_user(u) for u in thread.users]

        # Get last message info
        last_message = None
        last_message_at = None
        if thread.messages:
            last_msg = thread.messages[0]
            last_message = self._extract_message_text(last_msg)
            last_message_at = last_msg.timestamp

        # Thread title: use user names for non-group, thread_title for groups
        if thread.thread_title:
            title = thread.thread_title
        elif len(users) == 1:
            title = users[0].full_name or users[0].username
        else:
            title = ", ".join(u.username for u in users[:3])

        # Thread image
        thread_image = None
        if len(users) == 1 and users[0].profile_pic_url:
            thread_image = users[0].profile_pic_url

        return ThreadItem(
            thread_id=str(thread.id),
            thread_title=title,
            users=users,
            last_message=last_message,
            last_message_at=last_message_at,
            is_group=thread.is_group,
            muted=thread.muted,
            thread_image_url=thread_image,
        )

    def _convert_user(self, user: UserShort) -> UserInfo:
        """Convert instagrapi UserShort to our UserInfo schema."""
        return UserInfo(
            pk=user.pk,
            username=user.username,
            full_name=user.full_name or user.username,
            profile_pic_url=str(user.profile_pic_url) if user.profile_pic_url else None,
            is_verified=getattr(user, "is_verified", False),
            is_private=getattr(user, "is_private", False),
        )

    def _convert_message(self, msg: DirectMessage) -> MessageItem:
        """Convert instagrapi DirectMessage to our MessageItem schema."""
        message_type = self._detect_message_type(msg)
        text = self._extract_message_text(msg)
        media = self._extract_media(msg)
        reactions = self._extract_reactions(msg)

        return MessageItem(
            message_id=str(msg.id),
            user_id=msg.user_id,
            timestamp=msg.timestamp,
            message_type=message_type,
            text=text,
            media=media,
            reactions=reactions,
            is_sent_by_me=(msg.user_id == self._user_id),
        )

    def _detect_message_type(self, msg: DirectMessage) -> MessageType:
        """Detect the type of a direct message."""
        item_type = getattr(msg, "item_type", None) or ""
        
        type_map = {
            "text": MessageType.TEXT,
            "media": MessageType.MEDIA,
            "voice_media": MessageType.VOICE,
            "reel_share": MessageType.REEL_SHARE,
            "story_share": MessageType.STORY_SHARE,
            "link": MessageType.LINK,
            "like": MessageType.LIKE,
            "animated_media": MessageType.ANIMATED_MEDIA,
            "clip": MessageType.CLIP,
            "profile": MessageType.PROFILE,
            "placeholder": MessageType.PLACEHOLDER,
            "action_log": MessageType.ACTION_LOG,
            "media_share": MessageType.MEDIA,
        }
        
        return type_map.get(item_type, MessageType.TEXT if msg.text else MessageType.UNKNOWN)

    def _extract_message_text(self, msg: DirectMessage) -> Optional[str]:
        """Extract display text from a message."""
        if msg.text:
            return msg.text

        item_type = getattr(msg, "item_type", "") or ""

        if item_type == "like":
            return "❤️"
        elif item_type == "reel_share":
            return "📹 Shared a reel"
        elif item_type == "story_share":
            return "📖 Shared a story"
        elif item_type == "media":
            return "📷 Photo"
        elif item_type == "voice_media":
            return "🎤 Voice message"
        elif item_type == "animated_media":
            return "GIF"
        elif item_type == "clip":
            return "🎬 Clip"
        elif item_type == "action_log":
            return getattr(msg, "action_log", {}).get("description", "Action")

        return None

    def _extract_media(self, msg: DirectMessage) -> Optional[MediaInfo]:
        """Extract media info from a message."""
        # Check for media
        if hasattr(msg, "media") and msg.media:
            media = msg.media
            media_type = "image"
            url = None
            thumbnail = None

            if hasattr(media, "video_versions") and media.video_versions:
                media_type = "video"
                url = str(media.video_versions[0].url) if media.video_versions else None
                if hasattr(media, "image_versions2") and media.image_versions2:
                    candidates = media.image_versions2.get("candidates", [])
                    if candidates:
                        thumbnail = str(candidates[0].get("url", ""))
            elif hasattr(media, "image_versions2") and media.image_versions2:
                candidates = media.image_versions2.get("candidates", [])
                if candidates:
                    url = str(candidates[0].get("url", ""))

            if url:
                return MediaInfo(
                    url=url,
                    media_type=media_type,
                    thumbnail_url=thumbnail,
                )

        # Check for voice media
        if hasattr(msg, "voice_media") and msg.voice_media:
            voice = msg.voice_media
            if hasattr(voice, "media") and voice.media:
                audio = voice.media
                if hasattr(audio, "audio") and audio.audio:
                    return MediaInfo(
                        url=str(audio.audio.audio_src),
                        media_type="audio",
                    )

        return None

    def _extract_reactions(self, msg: DirectMessage) -> list[Reaction]:
        """Extract reactions from a message."""
        reactions = []
        if hasattr(msg, "reactions") and msg.reactions:
            if hasattr(msg.reactions, "emojis") and msg.reactions.emojis:
                for reaction in msg.reactions.emojis:
                    reactions.append(
                        Reaction(
                            emoji=reaction.emoji,
                            user_id=reaction.sender_id,
                            timestamp=getattr(reaction, "timestamp", None),
                        )
                    )
        return reactions


# Global singleton instance
instagram_service = InstagramService()
