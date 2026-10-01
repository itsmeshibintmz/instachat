# Deploy InstaChat Backend to Railway (one-time setup)

After this setup the backend runs 24/7 in the cloud — no MacBook needed.

---

## 1 — Create a Railway project

1. Go to **[railway.app](https://railway.app)** → sign in with GitHub
2. Click **New Project → Deploy from GitHub repo**
3. Choose `instachat` → click **Deploy Now**
4. Railway will auto-detect the `railway.toml` and build the Docker image

---

## 2 — Add a Volume for session persistence

Without a volume your Instagram session is lost every time the container restarts (= log in again every few days).

1. Railway dashboard → your project → click the **instachat** service
2. Left sidebar → **Volumes** → **Add Volume**
3. Mount path: `/app/sessions`
4. Click **Add** → Railway redeploys with the volume

---

## 3 — Get your public URL

1. Railway service → **Settings** → scroll to **Domains**
2. Click **Generate Domain** → you get something like `instachat-backend.up.railway.app`
3. Your backend URL is: `https://instachat-backend.up.railway.app`

---

## 4 — Add secrets to GitHub

These let GitHub Actions bake the backend URL into every APK/IPA build:

1. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

   | Secret name     | Value                                          |
   |-----------------|------------------------------------------------|
   | `BACKEND_URL`   | `https://instachat-backend.up.railway.app`     |
   | `RAILWAY_TOKEN` | Railway → Account Settings → Tokens → New Token |

---

## 5 — Trigger a build

Push any commit to `main` (or re-run the latest CI run). GitHub Actions will:
- Build Android APK + iOS IPA with the cloud URL baked in
- Auto-deploy the backend to Railway if backend files changed

---

## 6 — First login

Open the app → log in with your Instagram credentials.
The backend stores the session in `/app/sessions` (the volume you mounted).
You should only need to log in once — the session persists through restarts.

---

## Local development (still works)

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

Flutter app will use `http://10.0.2.2:8000` (Android emulator) or `http://localhost:8000` (iOS simulator) when `BASE_URL` is not set at build time.
