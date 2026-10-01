/// InstaChat — Personal Instagram Messenger
///
/// Entry point for the Flutter application.
/// Initializes providers and sets up platform-adaptive theming.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Use bundled / cached fonts only — no network fetching at runtime.
  // Prevents DNS errors on restricted networks; falls back to system font silently.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    const ProviderScope(
      child: InstaChat(),
    ),
  );
}
