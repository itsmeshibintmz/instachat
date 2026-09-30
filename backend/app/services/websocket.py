"""
WebSocket manager for real-time message delivery.

Handles client connections and broadcasts new messages
detected via polling.
"""
from __future__ import annotations

import asyncio
import json
import logging
from datetime import datetime
from typing import Optional

from fastapi import WebSocket
from starlette.websockets import WebSocketState

from app.config import POLL_INTERVAL
from app.models.schemas import WSEvent, WSEventType

logger = logging.getLogger("instachat.websocket")


class ConnectionManager:
    """Manages WebSocket connections and message broadcasting."""

    def __init__(self):
        self._connections: list[WebSocket] = []
        self._poll_task: Optional[asyncio.Task] = None
        self._last_inbox_state: dict[str, str] = {}  # thread_id -> last_message_id

    async def connect(self, websocket: WebSocket):
        """Accept and register a new WebSocket connection."""
        await websocket.accept()
        self._connections.append(websocket)
        logger.info(f"WebSocket client connected. Total: {len(self._connections)}")

    def disconnect(self, websocket: WebSocket):
        """Remove a disconnected WebSocket."""
        if websocket in self._connections:
            self._connections.remove(websocket)
        logger.info(f"WebSocket client disconnected. Total: {len(self._connections)}")

    async def broadcast(self, event: WSEvent):
        """Broadcast an event to all connected clients."""
        data = event.model_dump_json()
        disconnected = []

        for ws in self._connections:
            try:
                if ws.client_state == WebSocketState.CONNECTED:
                    await ws.send_text(data)
            except Exception as e:
                logger.warning(f"Failed to send to client: {e}")
                disconnected.append(ws)

        # Clean up disconnected clients
        for ws in disconnected:
            self.disconnect(ws)

    async def broadcast_new_message(self, thread_id: str, message_data: dict):
        """Broadcast a new message event."""
        event = WSEvent(
            event=WSEventType.NEW_MESSAGE,
            data={"thread_id": thread_id, "message": message_data},
        )
        await self.broadcast(event)

    async def broadcast_typing(self, thread_id: str, user_id: int, username: str):
        """Broadcast a typing indicator event."""
        event = WSEvent(
            event=WSEventType.TYPING,
            data={
                "thread_id": thread_id,
                "user_id": user_id,
                "username": username,
            },
        )
        await self.broadcast(event)

    async def broadcast_thread_update(self, thread_data: dict):
        """Broadcast a thread update (new message in inbox)."""
        event = WSEvent(
            event=WSEventType.THREAD_UPDATE,
            data=thread_data,
        )
        await self.broadcast(event)

    async def start_polling(self, instagram_service):
        """Start polling Instagram for new messages."""
        if self._poll_task and not self._poll_task.done():
            return  # Already running

        self._poll_task = asyncio.create_task(self._poll_loop(instagram_service))
        logger.info("Started inbox polling")

    async def stop_polling(self):
        """Stop the polling task."""
        if self._poll_task:
            self._poll_task.cancel()
            try:
                await self._poll_task
            except asyncio.CancelledError:
                pass
            self._poll_task = None
            logger.info("Stopped inbox polling")

    async def _poll_loop(self, instagram_service):
        """Background loop that polls Instagram for new messages."""
        while True:
            try:
                if not instagram_service.is_logged_in:
                    await asyncio.sleep(POLL_INTERVAL)
                    continue

                if not self._connections:
                    await asyncio.sleep(POLL_INTERVAL)
                    continue

                # Fetch inbox in a thread to avoid blocking
                inbox = await asyncio.to_thread(instagram_service.get_inbox, limit=10)

                for thread in inbox.threads:
                    if thread.last_message:
                        # Check if this thread has new content
                        prev_msg = self._last_inbox_state.get(thread.thread_id)
                        current_key = f"{thread.last_message}_{thread.last_message_at}"

                        if prev_msg != current_key:
                            self._last_inbox_state[thread.thread_id] = current_key

                            # Skip first run (don't spam on startup)
                            if prev_msg is not None:
                                await self.broadcast_thread_update(
                                    thread.model_dump(mode="json")
                                )

            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.error(f"Polling error: {e}")

            await asyncio.sleep(POLL_INTERVAL)

    @property
    def active_connections(self) -> int:
        return len(self._connections)


# Global singleton
ws_manager = ConnectionManager()
