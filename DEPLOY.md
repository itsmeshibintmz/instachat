# Deploy InstaChat Backend — Free on Koyeb

**Koyeb free tier:** 1 always-on nano instance — **no credit card, no catch**.  
After this 5-minute setup the backend runs 24/7 — no MacBook needed.

> ⚠️ **Why not Fly.io?** Fly.io now requires a credit card even for the free tier.  
> Koyeb is truly free with no payment method.

---

## 1 — Sign up on Koyeb (no CC)

Go to **[koyeb.com](https://www.koyeb.com)** → **Sign up** with GitHub.  
No credit card asked.

---

## 2 — Create the app (web dashboard — ~3 min)

1. Dashboard → **Create App**
2. **Deployment method:** GitHub
3. **Repository:** `instachat` | **Branch:** `main`
4. **Builder:** Dockerfile
5. **Dockerfile location:** `backend/Dockerfile`
6. **Service name:** `api`
7. **Port:** `8000`
8. **Environment variables:** *(leave empty for now)*
9. **App name:** `instachat-backend`
10. Click **Deploy**

Koyeb builds your Docker image and gives you a URL like:  
`https://instachat-backend-<hash>.koyeb.app`

---

## 3 — Add a Persistent Volume for session storage

Without this, your Instagram session is lost every time the container restarts.

1. Dashboard → your service → **Volumes** → **Add Volume**
2. **Mount path:** `/app/sessions`
3. **Size:** 1 GB (free)
4. Click **Save** → service redeploys

---

## 4 — Get your public URL

Dashboard → your app → **Domains** → copy the URL, e.g.:  
`https://instachat-backend-abc123.koyeb.app`

Test it: open `https://instachat-backend-abc123.koyeb.app/health` in a browser — you should see `{"status":"ok"}`.

---

## 5 — Add GitHub Secrets

1. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

   | Secret name       | Value |
   |-------------------|-------|
   | `BACKEND_URL`     | `https://instachat-backend-abc123.koyeb.app` |
   | `KOYEB_API_TOKEN` | Koyeb Dashboard → Account → API → New API Key |

2. Re-run the latest CI build (or push any commit to `main`) — APK/IPA rebuilt with the cloud URL baked in.

---

## 6 — First login

Open the app → enter your Instagram credentials.  
The backend stores the session at `/app/sessions` (persistent volume).  
You log in **once** — the session survives restarts.

---

## What about Google Fonts loading error in the app?

The terminal showed font loading errors from `fonts.gstatic.com`. This means the fonts are downloaded at runtime (slow / fails on first run). Fix: bundle the fonts locally:

```yaml
# app/pubspec.yaml — under flutter: section
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
```

But the app still works without this — it just falls back to the system font.

---

## Local development (still works)

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload

# On physical Android device via USB:
adb reverse tcp:8000 tcp:8000
# Run app with:
flutter run --dart-define=BASE_URL=http://127.0.0.1:8000
```
