# Deploy InstaChat Backend — Free Options

Both options are **100% free with no credit card**.

---

## Option A — ngrok (5 minutes, works right now)

The backend runs on your Mac and ngrok gives it a permanent public HTTPS URL.  
The app works from anywhere as long as your Mac is on.

### 1. Install ngrok

```bash
brew install ngrok/ngrok/ngrok
```

### 2. Create a free account (no CC)

```
ngrok config add-authtoken <token>
```

Sign up at **[ngrok.com](https://ngrok.com)** → free account → copy your auth token from the dashboard.  
Every free account gets a **permanent static domain** like `abc123.ngrok-free.app` — it never changes between restarts.

### 3. Start the backend + ngrok

Terminal 1 — backend:
```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Terminal 2 — ngrok:
```bash
ngrok http 8000
```

ngrok shows:
```
Forwarding  https://abc123.ngrok-free.app → http://localhost:8000
```

### 4. Set the URL in the Flutter app

Open the app → **Settings** → set Backend URL to:
```
https://abc123.ngrok-free.app
```

Tap **Save**. Done. The app now works from anywhere on any network.

### Make ngrok start automatically on Mac login

Create `~/Library/LaunchAgents/com.instachat.ngrok.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key>            <string>com.instachat.ngrok</string>
  <key>ProgramArguments</key> <array>
    <string>/opt/homebrew/bin/ngrok</string>
    <string>http</string>
    <string>8000</string>
  </array>
  <key>RunAtLoad</key>        <true/>
  <key>KeepAlive</key>        <true/>
</dict></plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.instachat.ngrok.plist
```

ngrok now starts automatically when your Mac boots.

---

## Option B — Render + UptimeRobot (true cloud, 10 minutes)

Backend lives in the cloud, no Mac needed. Both services are free, no CC.

### 1. Deploy on Render

1. **[render.com](https://render.com)** → Sign up with GitHub (no CC)
2. **New → Web Service → Connect a repository** → pick `instachat`
3. Settings:

   | Field | Value |
   |-------|-------|
   | Runtime | **Docker** |
   | Dockerfile path | `backend/Dockerfile` |
   | Instance type | **Free** |

4. Click **Create Web Service** — Render builds the Docker image (~3 min)
5. Copy your URL: `https://instachat-backend.onrender.com`
6. Test: open `https://instachat-backend.onrender.com/health` → `{"status":"ok"}`

### 2. Prevent sleep with UptimeRobot (free)

Render's free tier sleeps after 15 min idle. UptimeRobot pings it every 5 min to keep it awake.

1. **[uptimerobot.com](https://uptimerobot.com)** → Sign up (free, no CC)
2. **Add New Monitor:**
   - Type: **HTTP(S)**
   - Friendly name: InstaChat Backend
   - URL: `https://instachat-backend.onrender.com/health`
   - Monitoring interval: **5 minutes**
3. Click **Create Monitor**

The backend now stays awake 24/7. Your login session persists as long as you don't redeploy.

### 3. Add GitHub Secrets

| Secret | Value |
|--------|-------|
| `BACKEND_URL` | `https://instachat-backend.onrender.com` |
| `RENDER_DEPLOY_HOOK_URL` | Render dashboard → your service → Settings → **Deploy Hook** → copy URL |

### 4. First login

Open the app → log in with your Instagram credentials.  
Session is stored in Render's container filesystem and persists until the next deploy.

---

## Which should I use?

| | ngrok | Render + UptimeRobot |
|--|-------|---------------------|
| Mac needs to be on | ✅ Yes | ❌ No |
| Works when travelling | ✅ Yes (Mac at home stays on) | ✅ Yes, always |
| Session persistence | ✅ Permanent (on Mac disk) | ✅ Until next deploy |
| Setup time | **5 minutes** | 10 minutes |
| Reliability | Mac uptime | Render uptime |

**Start with ngrok — it works in 5 minutes.** Migrate to Render later if needed.
