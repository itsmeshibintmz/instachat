/// Settings provider — stores user preferences in SharedPreferences.
library;

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────────────────

const _kBaseUrl = 'settings_base_url';

// ─── Cloud / build-time default ──────────────────────────────────────────────
//
// Priority order:
//   1. User's saved URL in SharedPreferences          ← persists across restarts
//   2. --dart-define=BASE_URL=https://...             ← baked in at CI build time
//   3. Platform-specific localhost fallback           ← local dev only
//
// CI passes --dart-define=BASE_URL=$BACKEND_URL where BACKEND_URL is the
// Railway deployment secret set in GitHub → Settings → Secrets → Actions.

const _kBuildUrl = String.fromEnvironment('BASE_URL');

String defaultBaseUrl() {
  if (_kBuildUrl.isNotEmpty) return _kBuildUrl;
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

// ─── State ────────────────────────────────────────────────────────────────────

class AppSettings {
  final String baseUrl;
  final bool isLoaded;

  const AppSettings({
    required this.baseUrl,
    this.isLoaded = false,
  });

  AppSettings copyWith({String? baseUrl, bool? isLoaded}) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(AppSettings(baseUrl: defaultBaseUrl())) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_kBaseUrl);
    final buildUrl = defaultBaseUrl();

    // If there is a cloud URL baked into the APK at build time AND the saved
    // URL is a local/emulator address (from an old dev session), automatically
    // upgrade to the cloud URL so the user doesn't get a silent connection
    // error just because they previously tested with an ADB tunnel.
    final savedIsLocal = savedUrl != null &&
        (savedUrl.contains('10.0.2.2') ||
            savedUrl.contains('127.0.0.1') ||
            savedUrl.contains('localhost'));
    final buildIsCloud = _kBuildUrl.isNotEmpty &&
        !_kBuildUrl.contains('localhost') &&
        !_kBuildUrl.contains('127.0.0.1') &&
        !_kBuildUrl.contains('10.0.2.2');

    String effectiveUrl;
    if (savedUrl != null && savedUrl.isNotEmpty && !(savedIsLocal && buildIsCloud)) {
      effectiveUrl = savedUrl;
    } else {
      effectiveUrl = buildUrl;
      // Clear the stale local entry so it doesn't come back
      if (savedIsLocal && buildIsCloud) {
        await prefs.remove(_kBaseUrl);
      }
    }

    state = AppSettings(baseUrl: effectiveUrl, isLoaded: true);
  }

  Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), ''); // strip trailing /
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, trimmed);
    state = state.copyWith(baseUrl: trimmed);
  }

  Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrl);
    state = state.copyWith(baseUrl: defaultBaseUrl());
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
