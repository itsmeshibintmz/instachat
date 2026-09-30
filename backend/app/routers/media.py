"""
Media router — upload photos, videos, and voice messages.
"""
import uuid
from pathlib import Path

import aiofiles
from fastapi import APIRouter, HTTPException, UploadFile, File, Form

from app.config import MEDIA_DIR
from app.models.schemas import SendMessageResponse
from app.services.instagram import instagram_service

router = APIRouter(prefix="/media", tags=["Media"])


ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/quicktime"}
ALLOWED_AUDIO_TYPES = {"audio/mp4", "audio/m4a", "audio/mpeg", "audio/ogg", "audio/wav"}


async def _save_upload(file: UploadFile, subfolder: str) -> Path:
    """Save an uploaded file to the media directory."""
    ext = Path(file.filename).suffix if file.filename else ".bin"
    filename = f"{uuid.uuid4().hex}{ext}"
    dest_dir = MEDIA_DIR / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / filename

    async with aiofiles.open(dest, "wb") as f:
        content = await file.read()
        await f.write(content)

    return dest


@router.post("/send/photo", response_model=SendMessageResponse)
async def send_photo(
    thread_id: str = Form(...),
    file: UploadFile = File(...),
):
    """Upload and send a photo to a conversation thread."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {file.content_type}. Allowed: {ALLOWED_IMAGE_TYPES}",
        )

    saved_path = await _save_upload(file, "photos")
    try:
        result = instagram_service.send_photo(
            thread_id=thread_id, photo_path=str(saved_path)
        )
        return result
    finally:
        # Clean up after sending
        saved_path.unlink(missing_ok=True)


@router.post("/send/video", response_model=SendMessageResponse)
async def send_video(
    thread_id: str = Form(...),
    file: UploadFile = File(...),
):
    """Upload and send a video to a conversation thread."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    if file.content_type not in ALLOWED_VIDEO_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported video type: {file.content_type}. Allowed: {ALLOWED_VIDEO_TYPES}",
        )

    saved_path = await _save_upload(file, "videos")
    try:
        result = instagram_service.send_video(
            thread_id=thread_id, video_path=str(saved_path)
        )
        return result
    finally:
        saved_path.unlink(missing_ok=True)


@router.post("/send/voice", response_model=SendMessageResponse)
async def send_voice(
    thread_id: str = Form(...),
    file: UploadFile = File(...),
):
    """Upload and send a voice message to a conversation thread."""
    if not instagram_service.is_logged_in:
        raise HTTPException(status_code=401, detail="Not logged in")

    if file.content_type not in ALLOWED_AUDIO_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported audio type: {file.content_type}. Allowed: {ALLOWED_AUDIO_TYPES}",
        )

    saved_path = await _save_upload(file, "voice")
    try:
        result = instagram_service.send_voice(
            thread_id=thread_id, audio_path=str(saved_path)
        )
        return result
    finally:
        saved_path.unlink(missing_ok=True)
