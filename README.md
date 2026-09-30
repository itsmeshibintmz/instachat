# InstaChat

> Personal Instagram messaging app — separate from the main Instagram app.

## Architecture

- **Backend**: Python + FastAPI + [instagrapi](https://github.com/subzeroid/instagrapi)
- **Mobile**: Flutter (Android: Material Expressive, iOS: Liquid Glass)
- **Real-time**: WebSockets for live message updates

## Quick Start

### Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m app.main
```

The API server runs at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

### Mobile App

```bash
cd app
flutter pub get
flutter run
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login to Instagram |
| POST | `/auth/logout` | Logout |
| GET | `/auth/status` | Check session status |
| GET | `/inbox/` | Fetch conversations |
| GET | `/inbox/pending` | Fetch message requests |
| GET | `/inbox/search?q=` | Search users |
| GET | `/messages/{thread_id}` | Fetch messages |
| POST | `/messages/send/text` | Send text message |
| POST | `/messages/react` | React to a message |
| POST | `/media/send/photo` | Send a photo |
| POST | `/media/send/video` | Send a video |
| POST | `/media/send/voice` | Send voice message |
| WS | `/ws` | WebSocket for real-time updates |

## ⚠️ Disclaimer

This is a **personal-use** project. It uses Instagram's unofficial API which
may violate their Terms of Service. Do not distribute or use commercially.
Your account may be at risk of restrictions.
