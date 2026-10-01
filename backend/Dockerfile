# ── InstaChat Backend — production Docker image ───────────────────────────────
FROM python:3.12-slim

# System deps needed by instagrapi (Pillow / cryptography)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app/ ./app/

# Persistent dirs (mount a Railway volume at /app/sessions for session survival)
RUN mkdir -p sessions media

# Railway / Render inject PORT; fall back to 8000 locally
ENV INSTACHAT_PORT=8000
EXPOSE 8000

# Use shell form so $PORT is expanded at runtime
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-${INSTACHAT_PORT}}
