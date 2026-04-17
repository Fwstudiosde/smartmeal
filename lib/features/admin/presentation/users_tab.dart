import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';
import 'package:smartmeal/features/admin/presentation/user_detail_dialog.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  List<dynamic> _users = [];
  int _total = 0;
  int _page = 1;
  final int _limit = 20;
  bool _isLoading = false;
  String _search = '';
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(adminApiClientProvider).getUsers(
            page: _page,
            limit: _limit,
            search: _search.isEmpty ? null : _search,
          );
      setState(() {
        _users = res['users'] as List<dynamic>;
        _total = res['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _search = value;
        _page = 1;
      });
      _load();
    });
  }

  Future<void> _deleteUser(String id, String? email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User löschen?'),
        content: Text(
          '$email wird samt Profil, Rezepten, Likes und Follows endgültig gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(adminApiClientProvider).deleteUser(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _load();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _limit).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Email suchen…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$_total User gesamt',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('Keine User gefunden'))
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        final createdAt = (u['created_at'] ?? '').toString();
                        final dateOnly = createdAt.length >= 10
                            ? createdAt.substring(0, 10)
                            : createdAt;
                        final name = u['display_name'] ??
                            u['community_name'] ??
                            u['email'] ??
                            '?';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              name
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(color: Colors.blue[800]),
                            ),
                          ),
                          title: Text(
                            u['email'] ?? '(keine Email)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (u['display_name'] != null ||
                                  u['community_name'] != null)
                                Text(
                                  '${u['display_name'] ?? ''} ${u['community_name'] != null ? '@${u['community_name']}' : ''}'
                                      .trim(),
                                ),
                              Text(
                                '📝 ${u['recipes']} • 👥 ${u['followers']} Follower • folgt ${u['following']} • reg. $dateOnly',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => UserDetailDialog(
                              userId: u['id'] as String,
                              onDeleted: _load,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteUser(
                              u['id'] as String,
                              u['email'] as String?,
                            ),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1
                      ? () {
                          setState(() => _page--);
                          _load();
                        }
                      : null,
                ),
                Text('Seite $_page / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages
                      ? () {
                          setState(() => _page++);
                          _load();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
