/// Settings screen — backend URL, connection test, account, about.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  bool _testingConnection = false;
  _ConnectionResult? _connectionResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: settings.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });

    try {
      final client = ApiClient(baseUrl: url);
      final status = await client.getSessionStatus()
          .timeout(const Duration(seconds: 5));
      setState(() {
        _connectionResult = _ConnectionResult.success(
          status['logged_in'] == true
              ? 'Connected · logged in as @${status['username']}'
              : 'Connected · not logged in',
        );
      });
    } catch (e) {
      setState(() {
        _connectionResult = _ConnectionResult.failure(
          'Cannot reach backend. Check the URL and make sure the server is running.',
        );
      });
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await ref.read(settingsProvider.notifier).setBaseUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend URL saved — reconnecting…'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetUrl() async {
    await ref.read(settingsProvider.notifier).resetBaseUrl();
    _urlController.text = ref.read(settingsProvider).baseUrl;
    setState(() => _connectionResult = null);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to use InstaChat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final isIOS = Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: isIOS,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [

          // ── Connection ────────────────────────────────────────────────
          _SectionHeader('Connection', theme),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend URL',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: (_) => setState(() => _connectionResult = null),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.x.x:8000',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _urlController.clear();
                        setState(() => _connectionResult = null);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIOS
                      ? '• Simulator: http://localhost:8000\n• Physical iPhone: http://<mac-ip>:8000 (same WiFi)\n• USB (iproxy): http://127.0.0.1:8000'
                      : '• Emulator: http://10.0.2.2:8000\n• Physical device (USB): http://127.0.0.1:8000  ← run: adb reverse tcp:8000 tcp:8000\n• Same WiFi: http://<mac-ip>:8000',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _testingConnection ? null : _testConnection,
                        child: _testingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Test connection'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveUrl,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),

                // Connection result
                if (_connectionResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _connectionResult!.success
                          ? cs.primaryContainer.withValues(alpha: 0.5)
                          : cs.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionResult!.success
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 18,
                          color: _connectionResult!.success
                              ? cs.primary
                              : cs.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionResult!.message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _connectionResult!.success
                                  ? cs.onPrimaryContainer
                                  : cs.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show current saved URL
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Saved: ${settings.baseUrl}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetUrl,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reset',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // ── Account ───────────────────────────────────────────────────
          _SectionHeader('Account', theme),

          if (auth.profilePicUrl != null || auth.username != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: auth.profilePicUrl != null
                        ? NetworkImage(auth.profilePicUrl!)
                        : null,
                    child: auth.profilePicUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (auth.fullName != null)
                        Text(auth.fullName!,
                            style: theme.textTheme.titleMedium),
                      if (auth.username != null)
                        Text('@${auth.username!}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            )),
                    ],
                  ),
                ],
              ),
            ),

          ListTile(
            leading: Icon(Icons.logout_rounded, color: cs.error),
            title: Text('Log out',
                style: TextStyle(color: cs.error)),
            onTap: _logout,
          ),

          const Divider(height: 24),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader('About', theme),

          ListTile(
            leading: const Icon(Icons.tag_rounded),
            title: const Text('Version'),
            trailing: Text(
              'v1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded),
            title: const Text('Platform'),
            trailing: Text(
              Platform.isIOS ? 'iOS · Liquid Glass' : 'Android · Material 3',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy device info'),
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: 'Platform: ${Platform.isIOS ? 'iOS' : 'Android'}\n'
                    'Backend URL: ${settings.baseUrl}\n'
                    'Version: v1.0.0',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'InstaChat · Personal use only\nNot affiliated with Instagram or Meta',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.3),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader(this.title, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ConnectionResult {
  final bool success;
  final String message;
  _ConnectionResult.success(this.message) : success = true;
  _ConnectionResult.failure(this.message) : success = false;
}
