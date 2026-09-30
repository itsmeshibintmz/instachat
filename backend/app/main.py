"""
InstaChat Backend — FastAPI Application Entry Point

A personal Instagram messaging backend that wraps the instagrapi library
and exposes REST + WebSocket APIs for the Flutter mobile app.
"""
import logging

from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from app.config import HOST, PORT
from app.routers import auth, inbox, messages, media
from app.services.instagram import instagram_service
from app.services.websocket import ws_manager


# ─── Logging ─────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(name)-24s │ %(levelname)-7s │ %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("instachat")


# ─── Lifespan ────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown lifecycle."""
    logger.info("🚀 InstaChat Backend starting up...")
    yield
    logger.info("🛑 InstaChat Backend shutting down...")
    await ws_manager.stop_polling()


# ─── App ─────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="InstaChat API",
    description="Personal Instagram messaging backend",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS — allow the Flutter app from any origin (personal use)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(inbox.router)
app.include_router(messages.router)
app.include_router(media.router)


# ─── WebSocket ───────────────────────────────────────────────────────────────

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time message updates.
    
    The client connects here to receive:
    - new_message: When a new DM arrives
    - thread_update: When a thread's last message changes
    - typing: When someone is typing
    """
    await ws_manager.connect(websocket)
    try:
        while True:
            # Keep connection alive; client can send pings
            data = await websocket.receive_text()
            # Handle client commands if needed
            if data == "ping":
                await websocket.send_text('{"event":"pong"}')
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        ws_manager.disconnect(websocket)


# ─── Health ──────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "app": "InstaChat",
        "version": "0.1.0",
        "status": "running",
        "logged_in": instagram_service.is_logged_in,
        "ws_connections": ws_manager.active_connections,
    }


@app.get("/health")
async def health():
    return {"status": "ok"}


# ─── Run ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=HOST, port=PORT, reload=True)
