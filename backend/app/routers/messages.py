"""
Messages router — fetch, send, react, mark seen.
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.models.schemas import (
    ThreadMessagesResponse,
    SendTextRequest,
    SendMessageResponse,
    ReactionRequest,
)
from app.services.instagram import instagram_service

router = APIRouter(prefix="/messages", tags=["Messages"])


@router.get("/{thread_id}", response_model=ThreadMessagesResponse)
async def get_messages(
    thread_id: str,
    cursor: Optional[str] = Query(None, description="Pagination cursor for older messages"),
    limit: int = Query(50, ge=1, le=100, description="Number of messages to fetch"),
):
    """Fetch messages from a specific conversation thread."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    try:
        return instagram_service.get_thread_messages(
            thread_id=thread_id, cursor=cursor, limit=limit
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send/text", response_model=SendMessageResponse)
async def send_text(request: SendTextRequest):
    """Send a text message to a conversation thread."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    return instagram_service.send_text(
        thread_id=request.thread_id,
        text=request.text,
        reply_to_message_id=request.reply_to_message_id,
    )


@router.post("/react", response_model=SendMessageResponse)
async def react_to_message(request: ReactionRequest):
    """React to a message with an emoji."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    return instagram_service.react_to_message(
        thread_id=request.thread_id,
        message_id=request.message_id,
        emoji=request.emoji,
    )


@router.post("/unreact", response_model=SendMessageResponse)
async def unreact_to_message(request: ReactionRequest):
    """Remove a reaction from a message."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    return instagram_service.unreact_to_message(
        thread_id=request.thread_id,
        message_id=request.message_id,
    )


@router.post("/{thread_id}/seen")
async def mark_as_seen(
    thread_id: str,
    message_id: Optional[str] = Query(None, description="Last seen message ID (optional)"),
):
    """Mark all messages in a thread as seen."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    success = instagram_service.mark_seen(
        thread_id=thread_id, message_id=message_id or ""
    )
    return {"success": success}
