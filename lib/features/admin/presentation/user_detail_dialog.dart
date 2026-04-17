import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';
import 'package:smartmeal/features/admin/presentation/recipe_detail_dialog.dart';

class UserDetailDialog extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onDeleted;

  const UserDetailDialog({
    super.key,
    required this.userId,
    this.onDeleted,
  });

  @override
  ConsumerState<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends ConsumerState<UserDetailDialog> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref
          .read(adminApiClientProvider)
          .getUserDetail(widget.userId);
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User löschen?'),
        content: Text(
          '${_data?['email']} wird samt Profil, Rezepten, Likes, Follows und Meal-Plans endgültig gelöscht.',
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
      await ref.read(adminApiClientProvider).deleteUser(widget.userId);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? SizedBox(
                    height: 300,
                    child: Center(child: Text('Fehler: $_error')),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    final profile = data['profile'] as Map? ?? {};
    final stats = data['stats'] as Map? ?? {};
    final recipes = (data['recipes'] as List<dynamic>?) ?? [];

    final email = data['email'] as String? ?? '(keine Email)';
    final createdAt = (data['created_at'] ?? '').toString();
    final lastSignIn = (data['last_sign_in'] ?? '').toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: profile['display_name'] ??
              profile['community_name'] ??
              email,
          subtitle: email,
          onClose: () => Navigator.pop(context),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Account', [
                  _row('User ID', data['id']?.toString() ?? ''),
                  _row('Email', email),
                  _row('Registriert',
                      createdAt.isEmpty ? '–' : createdAt.substring(0, 19)),
                  _row(
                    'Letzter Login',
                    lastSignIn.isEmpty ? '–' : lastSignIn.substring(0, 19),
                  ),
                ]),
                const SizedBox(height: 16),
                _section('Profil', [
                  _row('Display Name', profile['display_name'] ?? '–'),
                  _row(
                    'Community Name',
                    profile['community_name'] != null
                        ? '@${profile['community_name']}'
                        : '–',
                  ),
                  _row(
                    'Supermärkte',
                    (profile['preferred_supermarkets'] as List?)?.join(', ') ??
                        '–',
                  ),
                  _row(
                    'Ernährung',
                    (profile['dietary_preferences'] as List?)?.join(', ') ??
                        '–',
                  ),
                  _row(
                    'Benachr. aktiv',
                    profile['notifications_enabled'] == true ? 'Ja' : 'Nein',
                  ),
                  _row(
                    'Deal-Alerts',
                    profile['deal_alerts_enabled'] == true ? 'Ja' : 'Nein',
                  ),
                  _row(
                    'Metrische Einheiten',
                    profile['metric_units'] == true ? 'Ja' : 'Nein',
                  ),
                ]),
                const SizedBox(height: 16),
                _statsGrid(stats),
                const SizedBox(height: 16),
                _section(
                  'Rezepte (${recipes.length})',
                  recipes.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('(noch keine Rezepte)'),
                          ),
                        ]
                      : recipes.map((r) {
                          final created = (r['created_at'] ?? '').toString();
                          final dateOnly = created.length >= 10
                              ? created.substring(0, 10)
                              : created;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: _thumb(r['image_url']),
                            title: Text(r['name'] ?? '?'),
                            subtitle: Text(
                              '$dateOnly • ${r['is_public'] == true ? 'öffentlich' : 'privat'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => RecipeDetailDialog(
                                  recipeId: r['id'] as String,
                                  onDeleted: () {
                                    _load();
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _deleteUser,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'User löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(Map stats) {
    final items = [
      ('Rezepte', stats['recipes'] ?? 0, Icons.restaurant_menu),
      ('Follower', stats['followers'] ?? 0, Icons.people_outline),
      ('Folgt', stats['following'] ?? 0, Icons.person_add_outlined),
      ('Likes', stats['likes_given'] ?? 0, Icons.favorite_outline),
      ('Gespeichert', stats['saves_given'] ?? 0, Icons.bookmark_outline),
      ('Pantry', stats['pantry_items'] ?? 0, Icons.kitchen_outlined),
      ('Meal-Plans', stats['meal_plans'] ?? 0, Icons.calendar_today),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items.map((item) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, size: 16, color: Colors.grey[600]),
                const Spacer(),
                Text(
                  '${item.$2}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.$1,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _thumb(dynamic url) {
    if (url == null || (url is String && url.isEmpty)) {
      return CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url.toString(),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue[100],
            child: Text(
              title.isEmpty ? '?' : title.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
