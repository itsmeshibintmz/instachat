/// InstaChat — Personal Instagram Messenger
///
/// Entry point for the Flutter application.
/// Initializes providers and sets up platform-adaptive theming.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: InstaChat(),
    ),
  );
}
