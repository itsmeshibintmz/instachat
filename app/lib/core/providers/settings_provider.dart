/// Settings provider — stores user preferences in SharedPreferences.
library;

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────────────────

const _kBaseUrl = 'settings_base_url';

// ─── Default URL helper ───────────────────────────────────────────────────────

String defaultBaseUrl() {
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
    state = AppSettings(
      baseUrl: (savedUrl != null && savedUrl.isNotEmpty)
          ? savedUrl
          : defaultBaseUrl(),
      isLoaded: true,
    );
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
