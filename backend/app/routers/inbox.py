"""
Inbox router — conversation list, pending requests.
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.models.schemas import InboxResponse, SearchUsersResponse
from app.services.instagram import instagram_service

router = APIRouter(prefix="/inbox", tags=["Inbox"])


@router.get("/", response_model=InboxResponse)
async def get_inbox(
    cursor: Optional[str] = Query(None, description="Pagination cursor"),
    limit: int = Query(20, ge=1, le=50, description="Number of threads to fetch"),
):
    """Fetch the inbox (list of conversations)."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    try:
        return instagram_service.get_inbox(cursor=cursor, limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/pending", response_model=InboxResponse)
async def get_pending_inbox():
    """Fetch pending message requests."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    try:
        return instagram_service.get_pending_inbox()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search", response_model=SearchUsersResponse)
async def search_users(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(20, ge=1, le=50),
):
    """Search for Instagram users to start a conversation."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    try:
        users = instagram_service.search_users(query=q, limit=limit)
        return SearchUsersResponse(users=users)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/create")
async def create_thread(user_ids: list[int], message: str = ""):
    """Create a new DM thread with given user IDs."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    thread_id = instagram_service.create_thread(user_ids=user_ids, message=message)
    if thread_id:
        return {"success": True, "thread_id": thread_id}
    raise HTTPException(status_code=500, detail="Failed to create thread")
