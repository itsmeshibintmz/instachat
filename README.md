<div align="center">

<br />

# 💬 InstaChat

**Your Instagram DMs. Without Instagram.**

A clean, fast, native messaging app for Instagram — built with Flutter and Python.  
No ads. No reels. No distractions. Just your conversations.

<br />

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?style=flat-square&logo=fastapi)](https://fastapi.tiangolo.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)](https://flutter.dev)

<br />

</div>

---

## ✨ What it does

| | |
|---|---|
| 💬 | Send and receive messages in real-time |
| 📷 | Share photos and videos |
| 🎤 | Send voice messages |
| ❤️ | React to messages with emoji |
| 🔍 | Search your conversations |
| 🔔 | Live updates via WebSocket — no manual refresh |
| 🌙 | Dark and light mode, follows your system |
| 📱 | Feels native on both Android and iOS |

---

## 🎨 Design

InstaChat adapts its look completely to your platform:

**Android** — Material 3 Expressive  
Vibrant purple & pink accents, pill-shaped elements, expressive typography

**iOS** — Liquid Glass  
Frosted translucent surfaces, SF-like type, iOS 26 aesthetic

---

## 🏗 How it works

```
Flutter App  ──────►  FastAPI Backend  ──────►  Instagram
  (your phone)          (runs locally)         (via instagrapi)
```

The app never talks to Instagram directly — everything routes through a small Python server running on your machine. This keeps things clean and lets the backend handle all the auth complexity.

---

## 🚀 Running locally

### Backend
```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### App
```bash
cd app
flutter pub get
flutter run
```

> **Python 3.12 is required** — newer versions break a pydantic dependency.

---

## 🗺 Roadmap

- [x] Login with 2FA support
- [x] Inbox & conversation list
- [x] Real-time messaging via WebSocket
- [x] Send images & videos
- [ ] Voice messages
- [ ] Message reactions
- [ ] Story replies
- [ ] Notifications
- [ ] Offline caching
- [ ] Settings screen

---

## ⚠️ Heads up

This uses Instagram's **unofficial API** — it's for personal use only.
Don't distribute it. Your account could get restricted if Instagram flags the activity.

---

<div align="center">
<br />
Made for personal use &nbsp;·&nbsp; Not affiliated with Instagram or Meta
</div>
