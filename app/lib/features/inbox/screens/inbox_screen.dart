import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_providers.dart';
import '../../chat/screens/chat_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/thread_tile.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch inbox on first load
    Future.microtask(() {
      ref.read(inboxProvider.notifier).fetchInbox();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(ThreadItem thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(thread: thread),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(inboxProvider.notifier).refreshInbox();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // User avatar
            if (authState.profilePicUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(authState.profilePicUrl!),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, size: 18, color: cs.primary),
              ),
            const SizedBox(width: 12),
            Text(
              authState.username ?? 'InstaChat',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'requests',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread_outlined),
                    SizedBox(width: 12),
                    Text('Message Requests'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild for filtering
                },
              ),
            ),

          // Thread list
          Expanded(
            child: _buildInboxContent(inboxState, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: New message
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _buildInboxContent(InboxState state, ThemeData theme) {
    if (state.isLoading && state.threads.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load inbox',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(inboxProvider.notifier).fetchInbox();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Filter threads if searching
    var threads = state.threads;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      threads = threads
          .where((t) =>
              t.threadTitle.toLowerCase().contains(query) ||
              t.users.any((u) => u.username.toLowerCase().contains(query)))
          .toList();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return ThreadTile(
            thread: thread,
            onTap: () => _openChat(thread),
          );
        },
      ),
    );
  }
}
