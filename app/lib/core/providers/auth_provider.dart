/// Auth state provider using Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'settings_provider.dart';

// API Client provider — re-created whenever the saved base URL changes
final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsProvider);
  return ApiClient(baseUrl: settings.baseUrl);
});

// Auth state
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool requires2FA;
  final int? userId;
  final String? username;
  final String? fullName;
  final String? profilePicUrl;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.requires2FA = false,
    this.userId,
    this.username,
    this.fullName,
    this.profilePicUrl,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? requires2FA,
    int? userId,
    String? username,
    String? fullName,
    String? profilePicUrl,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      requires2FA: requires2FA ?? this.requires2FA,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final status = await _api.getSessionStatus();
      if (status['logged_in'] == true) {
        state = state.copyWith(
          isLoggedIn: true,
          userId: status['user_id'] as int?,
          username: status['username'] as String?,
        );
      }
    } catch (_) {
      // Backend not reachable, stay logged out
    }
  }

  Future<void> login(String username, String password,
      {String? verificationCode}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _api.login(
        username,
        password,
        verificationCode: verificationCode,
      );

      if (result['success'] == true) {
        state = AuthState(
          isLoggedIn: true,
          userId: result['user_id'] as int?,
          username: result['username'] as String?,
          fullName: result['full_name'] as String?,
          profilePicUrl: result['profile_pic_url'] as String?,
        );
      } else if (result['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading: false,
          requires2FA: true,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] as String? ?? 'Login failed',
        );
      }
    } catch (e) {
      final msg = e.toString();
      final String errorText;
      if (msg.contains('TimeoutException')) {
        errorText =
            'Login timed out — Instagram is taking too long to respond.\nTry again in a moment.';
      } else if (msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('Failed host lookup')) {
        errorText =
            'Cannot reach server at ${_api.baseUrl}\nCheck Settings → Backend URL.';
      } else {
        errorText =
            'Connection error — could not reach ${_api.baseUrl}\n'
            'Check Settings → Backend URL.';
      }
      state = state.copyWith(isLoading: false, error: errorText);
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
