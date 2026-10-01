# Deploy InstaChat Backend — Free on Fly.io

**Fly.io free tier:** 3 always-on VMs + 3 GB volumes — **no credit card required**.  
After this 10-minute setup the backend runs 24/7 in the cloud — no MacBook needed.

---

## 1 — Install flyctl (the Fly.io CLI)

```bash
# macOS
brew install flyctl

# or universal installer
curl -L https://fly.io/install.sh | sh
```

---

## 2 — Sign up / log in (free)

```bash
flyctl auth signup   # creates a free account (no CC needed)
# or
flyctl auth login    # if you already have an account
```

---

## 3 — Create the app and volume on Fly.io

```bash
cd backend

# Launch the app (reads fly.toml — answer prompts, don't deploy yet)
flyctl launch --no-deploy --config fly.toml

# Create the persistent volume for Instagram sessions
# (survives container restarts so you stay logged in)
flyctl volumes create instachat_sessions --size 1 --region sin
```

> **Tip:** `sin` = Singapore. You can pick a closer region with `flyctl platform regions`.

---

## 4 — Deploy

```bash
# Still in backend/
flyctl deploy --config fly.toml
```

Watch the build logs. When it says `✓ Machine started`, the backend is live.

---

## 5 — Get your public URL

```bash
flyctl status --config fly.toml
```

You'll see something like:
```
Hostname = instachat-backend.fly.dev
```

Your backend URL is: `https://instachat-backend.fly.dev`

---

## 6 — Add GitHub Secrets

These let GitHub Actions auto-deploy and bake the URL into every APK/IPA build.

1. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

   | Secret name    | Value |
   |----------------|-------|
   | `BACKEND_URL`  | `https://instachat-backend.fly.dev` |
   | `FLY_API_TOKEN`| output of `flyctl tokens create deploy -x 999999h` |

2. Re-run the latest CI build (or push any commit to `main`) — the APK/IPA will be rebuilt with the cloud URL baked in.

---

## 7 — First login

Open the app → log in with your Instagram credentials.  
The backend stores the session at `/app/sessions` (mounted volume).  
You log in **once** — the session persists across restarts.

---

## Koyeb (alternative — also 100% free)

If Fly.io doesn't work for you, [Koyeb](https://koyeb.com) also offers a free always-on instance with Docker:

1. koyeb.com → New App → Docker → point to your GitHub repo
2. Build command: `docker build -f backend/Dockerfile .`
3. Port: `8000`
4. Environment variable: `SESSION_DIR=/app/sessions`
5. Add a Koyeb Persistent Volume at `/app/sessions`

---

## Local development (still works)

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload
# Flutter app auto-uses http://10.0.2.2:8000 (Android) / localhost (iOS)
```
