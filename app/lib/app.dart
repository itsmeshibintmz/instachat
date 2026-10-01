import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/inbox/screens/inbox_screen.dart';
import 'theme/material_expressive.dart';
import 'theme/liquid_glass.dart';

class InstaChat extends ConsumerWidget {
  const InstaChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
