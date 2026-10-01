# InstaChat — Flutter App

The Flutter frontend for InstaChat. See the [root README](../README.md) for the full project overview.

---

## Project structure

```
app/
├── lib/
│   ├── core/
│   │   ├── api/          # ApiClient — HTTP + WebSocket calls to the backend
│   │   ├── models/       # Dart data models (ThreadItem, Message, UserInfo…)
│   │   ├── providers/    # Riverpod state (auth, settings, inbox, messages)
│   │   └── theme/        # Material 3 + iOS Liquid Glass themes
│   └── features/
│       ├── auth/         # Login screen
│       ├── inbox/        # Inbox list, pending requests
│       ├── chat/         # Message thread, send bar, media picker
│       └── settings/     # Backend URL, connection test, account
├── assets/
│   └── icon/             # Source PNGs for flutter_launcher_icons
└── pubspec.yaml
```

## Key dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `http` | REST calls to the FastAPI backend |
| `web_socket_channel` | Live message updates |
| `shared_preferences` | Persists backend URL across restarts |
| `image_picker` | Camera & gallery for photo/video sending |
| `record` / `audioplayers` | Voice message recording & playback |
| `cached_network_image` | Profile pictures with caching |
| `google_fonts` | Typography |
| `flutter_launcher_icons` | Generates all platform icon sizes |

## Build-time config

The backend URL is baked in at compile time:

```bash
flutter build apk --release --dart-define=BASE_URL=https://your-backend.onrender.com
```

If `BASE_URL` is not provided, the app falls back to `http://10.0.2.2:8000` on Android and `http://localhost:8000` on iOS (local dev defaults). Users can always override the URL in **Settings**.

## Run locally

```bash
flutter pub get
flutter run
# or with a specific backend:
flutter run --dart-define=BASE_URL=http://192.168.1.x:8000
```
