"""
InstaChat Backend Configuration
"""
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Base directories
BASE_DIR = Path(__file__).resolve().parent.parent
SESSION_DIR = BASE_DIR / "sessions"
MEDIA_DIR = BASE_DIR / "media"

# Create directories
SESSION_DIR.mkdir(exist_ok=True)
MEDIA_DIR.mkdir(exist_ok=True)

# Server config
HOST = os.getenv("INSTACHAT_HOST", "0.0.0.0")
# Railway / Render inject PORT; INSTACHAT_PORT is the local override
PORT = int(os.getenv("PORT") or os.getenv("INSTACHAT_PORT", "8000"))

# Instagram polling interval (seconds)
POLL_INTERVAL = int(os.getenv("INSTACHAT_POLL_INTERVAL", "5"))

# Max messages to fetch per thread
MAX_MESSAGES_PER_FETCH = int(os.getenv("INSTACHAT_MAX_MESSAGES", "50"))

# Encryption key for session storage (auto-generated if not set)
ENCRYPTION_KEY = os.getenv("INSTACHAT_ENCRYPTION_KEY", None)
