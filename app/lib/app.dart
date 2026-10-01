import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/websocket_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/inbox/screens/inbox_screen.dart';
import 'theme/material_expressive.dart';
import 'theme/liquid_glass.dart';

class InstaChat extends ConsumerStatefulWidget {
  const InstaChat({super.key});

  @override
  ConsumerState<InstaChat> createState() => _InstaChatState();
}

class _InstaChatState extends ConsumerState<InstaChat> {
  @override
  void initState() {
    super.initState();
    // If a saved session is restored before the first build, connect WS now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(wsProvider.notifier).connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Connect WS right after login; disconnect right after logout.
    ref.listen<AuthState>(authProvider, (prev, next) {
      final wasLoggedIn = prev?.isLoggedIn ?? false;
      if (!wasLoggedIn && next.isLoggedIn) {
        ref.read(wsProvider.notifier).connect();
      } else if (wasLoggedIn && !next.isLoggedIn) {
        ref.read(wsProvider.notifier).disconnect();
      }
    });

    return MaterialApp(
      title: 'InstaChat',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: authState.isLoggedIn ? const InboxScreen() : const LoginScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    if (Platform.isIOS) {
      return LiquidGlassTheme.light();
    }
    return MaterialExpressiveTheme.light();
  }

  ThemeData _buildDarkTheme() {
    if (Platform.isIOS) {
      return LiquidGlassTheme.dark();
    }
    return MaterialExpressiveTheme.dark();
  }
}
