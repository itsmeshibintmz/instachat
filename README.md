<div align="center">

<br />

<img src="app/assets/icon/icon.png" width="96" height="96" alt="InstaChat icon" />

<br />

# InstaChat

**Your Instagram DMs. Clean and fast.**

No ads. No Reels. No algorithm. Just your conversations.

<br />

[![Latest Release](https://img.shields.io/github/v/release/itsmeshibintmz/instachat?style=flat-square&label=Download&color=6C63FF)](https://github.com/itsmeshibintmz/instachat/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/itsmeshibintmz/instachat/build.yml?branch=main&style=flat-square&label=Build)](https://github.com/itsmeshibintmz/instachat/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)](https://flutter.dev)

<br />

[**⬇ Download APK**](https://github.com/itsmeshibintmz/instachat/releases/latest) &nbsp;·&nbsp; [All Releases](https://github.com/itsmeshibintmz/instachat/releases) &nbsp;·&nbsp; [Actions](https://github.com/itsmeshibintmz/instachat/actions)

<br />

</div>

---

## What it does

| | Feature |
|---|---|
| 💬 | Send & receive messages in real-time |
| 📷 | Share photos and videos |
| 🎤 | Voice messages |
| ❤️ | React to messages with emoji |
| 🔍 | Search conversations |
| ⚡ | Live updates via WebSocket |
| 🌙 | Dark & light mode, follows system |
| 📱 | Native feel on Android (Material 3) and iOS (Liquid Glass) |

---

## How it works

```
Your Phone  ──────►  FastAPI Backend  ──────►  Instagram
 (Flutter)            (Render cloud)           (instagrapi)
```

The app connects to a small Python server running on [Render](https://render.com) (free cloud hosting). The backend talks to Instagram on your behalf using [instagrapi](https://github.com/subzeroid/instagrapi). Your phone never contacts Instagram directly.

The backend is **always on** — no Mac required. A [UptimeRobot](https://uptimerobot.com) monitor pings it every 5 minutes to prevent sleep.

---

## Install on Android

1. Go to [**Releases**](https://github.com/itsmeshibintmz/instachat/releases/latest)
2. Download `instachat.apk`
3. On your phone: **Settings → Install unknown apps** → allow for your browser/Files app
4. Open the downloaded APK and install
5. Launch InstaChat → log in with your Instagram credentials

> The cloud backend URL is already baked into every release APK — no setup needed.

## Install on iOS (sideload)

The IPA is **unsigned** — you need a sideloading tool:

- [AltStore](https://altstore.io) — recommended
- [Sideloadly](https://sideloadly.io)

Download `instachat.ipa` from [Releases](https://github.com/itsmeshibintmz/instachat/releases/latest) and load it through your chosen tool.

---

## Run locally (for developers)

<details>
<summary>Local backend setup</summary>

### Backend

```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

> Python 3.12 required — newer versions break a pydantic dependency.

### Connect app to local backend

| Device | Command | URL in Settings |
|---|---|---|
| Android emulator | *(nothing)* | `http://10.0.2.2:8000` |
| Android via USB | `adb reverse tcp:8000 tcp:8000` | `http://127.0.0.1:8000` |
| iOS Simulator | *(nothing)* | `http://localhost:8000` |
| Same Wi-Fi | *(nothing)* | `http://<your-mac-ip>:8000` |

Open the app → **Settings → Backend URL → change → Save → Test connection**.

### Flutter app

```bash
cd app
flutter pub get
flutter run
```

</details>

---

## CI / CD

| Workflow | Trigger | Output |
|---|---|---|
| **Build** | Every push to `main` | Debug APK + IPA → `latest` pre-release |
| **Release** | Manual (`Actions → Release → Run workflow`) | Versioned APK + IPA → GitHub Release |
| **Deploy Backend** | Push to `main` touching `backend/` | Re-deploys to Render automatically |

To create a new release: **[Actions → Release → Run workflow](https://github.com/itsmeshibintmz/instachat/actions/workflows/release.yml)** → enter version (e.g. `1.6.0`).

---

## Roadmap

### Done ✅
- Login with 2FA support
- Inbox & conversation list
- Real-time messaging (WebSocket)
- Send photos, videos, voice messages
- Message reactions (tap to toggle)
- Settings screen (backend URL, connection test, account)
- App icon — all variants (adaptive, dark, monochrome)
- Cloud backend on Render — no Mac required
- CI/CD — auto debug builds + one-click releases
- Better connection error UX (shows URL, 15 s timeout)

### Coming up 🔜
- [ ] Read receipts & typing indicators
- [ ] Load older messages (pagination)
- [ ] Push notifications (background)
- [ ] Offline message cache
- [ ] Story replies

---

## ⚠️ Heads up

This uses Instagram's **unofficial API**. It's for personal use only — don't distribute it publicly. Your account could get restricted if Instagram flags unusual activity.

---

<div align="center">
<br />
Made for personal use &nbsp;·&nbsp; Not affiliated with Instagram or Meta
</div>
