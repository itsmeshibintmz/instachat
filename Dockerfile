# ── Render / cloud deployment Dockerfile ──────────────────────────────────────
# Placed at repo root so Render's Docker build context (always the repo root)
# can correctly resolve COPY paths to backend/.
#
# For local development, use: cd backend && docker build .

FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app/ ./app/

RUN mkdir -p sessions media

ENV INSTACHAT_PORT=8000
EXPOSE 8000

CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-${INSTACHAT_PORT}}
