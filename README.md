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
[![CI](https://img.shields.io/github/actions/workflow/status/itsmeshibintmz/instachat/build.yml?branch=main&style=flat-square&label=CI)](https://github.com/itsmeshibintmz/instachat/actions)
[![Release](https://img.shields.io/github/v/release/itsmeshibintmz/instachat?style=flat-square&label=Latest)](https://github.com/itsmeshibintmz/instachat/releases/latest)

<br />

[**Download v1.0.0**](https://github.com/itsmeshibintmz/instachat/releases/latest) · [CI Builds](https://github.com/itsmeshibintmz/instachat/actions) · [All Releases](https://github.com/itsmeshibintmz/instachat/releases)

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
| ⚙️ | Settings screen — configure backend URL, test connection, manage account |
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
  (your phone)          (runs on Mac)          (via instagrapi)
```

The app never talks to Instagram directly — everything routes through a small Python server on your machine. This keeps things clean and lets the backend handle all auth complexity.

---

## 🚀 Running locally

### 1 — Start the backend

```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 2 — Connect the backend to your phone

| Setup | Command | URL to use in app |
|---|---|---|
| **Android emulator** | *(nothing)* | `http://10.0.2.2:8000` |
| **Android via USB** | `adb reverse tcp:8000 tcp:8000` | `http://127.0.0.1:8000` |
| **iOS Simulator** | *(nothing)* | `http://localhost:8000` |
| **Same WiFi** | *(nothing)* | `http://<your-mac-ip>:8000` |

### 3 — Run the app

```bash
cd app
flutter pub get
flutter run
```

> Go to **Settings → Connection** in the app to configure the backend URL. Tap **Test connection** to verify it works before logging in.

> **Python 3.12 is required** — newer versions break a pydantic dependency.

---

## 📦 Releases

### Download
Latest stable: **[github.com/itsmeshibintmz/instachat/releases/latest](https://github.com/itsmeshibintmz/instachat/releases/latest)**  
Includes `instachat.apk` (Android) + `instachat.ipa` (iOS, unsigned).

### Rolling debug build
Every merge to `main` auto-builds and publishes to the [Latest Debug Build](https://github.com/itsmeshibintmz/instachat/releases/tag/latest) pre-release.

### Create a new versioned release
Go to **[Actions → Release → Run workflow](https://github.com/itsmeshibintmz/instachat/actions/workflows/release.yml)**,  
enter a version (e.g. `1.1.0`) and changelog — everything else is automatic.

### Install on Android
1. Download `instachat.apk`
2. Enable **Install unknown apps** on your device
3. Open the APK and install

### Install on iOS (sideload)
The IPA is unsigned. Use [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io).

---

## 🗺 Roadmap

- [x] Login with 2FA support
- [x] Inbox & conversation list
- [x] Real-time messaging via WebSocket
- [x] Send images & videos
- [x] Voice messages
- [x] Message reactions (tap to toggle, highlighted own reactions)
- [x] Settings screen (backend URL, connection test, account)
- [x] CI/CD — auto debug builds + one-click versioned releases
- [ ] Read receipts / typing indicators
- [ ] Message pagination (load older messages)
- [ ] Push notifications (background)
- [ ] Offline caching
- [ ] Story replies
- [ ] App icon + splash screen

---

## ⚠️ Heads up

This uses Instagram's **unofficial API** — it's for personal use only.  
Don't distribute it. Your account could get restricted if Instagram flags the activity.

---

<div align="center">
<br />
Made for personal use &nbsp;·&nbsp; Not affiliated with Instagram or Meta
</div>
