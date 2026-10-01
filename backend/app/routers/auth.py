"""
Authentication router — login, logout, session status.
"""
import asyncio

from fastapi import APIRouter

from app.models.schemas import LoginRequest, LoginResponse, SessionStatus
from app.services.instagram import instagram_service
from app.services.websocket import ws_manager

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """
    Login to Instagram.

    instagram_service.login() is synchronous and can take 15-60 s
    (instagrapi makes several network calls to Instagram).
    Run it in a thread so the event loop stays free for health checks,
    WebSocket pings, and UptimeRobot during the wait.

    If 2FA is enabled, the first call returns requires_2fa=True.
    Send the verification_code in a second request.
    """
    result = await asyncio.to_thread(
        instagram_service.login,
        request.username,
        request.password,
        request.verification_code,
    )

    # Start polling if login succeeded
    if result.success:
        await ws_manager.start_polling(instagram_service)

    return result


@router.post("/logout")
async def logout():
    """Logout and destroy the session."""
    await ws_manager.stop_polling()
    instagram_service.logout()
    return {"success": True, "message": "Logged out successfully."}


@router.get("/status", response_model=SessionStatus)
async def session_status():
    """Check if there's an active Instagram session."""
    return SessionStatus(
        logged_in=instagram_service.is_logged_in,
        user_id=instagram_service.user_id,
        username=instagram_service.username,
    )
