import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';
import 'package:smartmeal/features/admin/presentation/recipe_detail_dialog.dart';

class ModerationTab extends ConsumerStatefulWidget {
  const ModerationTab({super.key});

  @override
  ConsumerState<ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends ConsumerState<ModerationTab> {
  List<dynamic> _recipes = [];
  int _total = 0;
  int _page = 1;
  final int _limit = 20;
  bool _isLoading = false;
  String _search = '';
  String _sort = 'newest';
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
      final res = await ref.read(adminApiClientProvider).getCommunityRecipes(
            page: _page,
            limit: _limit,
            search: _search.isEmpty ? null : _search,
            sort: _sort,
          );
      setState(() {
        _recipes = res['recipes'] as List<dynamic>;
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

  Future<void> _deleteRecipe(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: Text('$name wird endgültig entfernt.'),
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
      await ref.read(adminApiClientProvider).deleteCommunityRecipe(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezept gelöscht'),
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

  void _showPreview(Map recipe) {
    showDialog(
      context: context,
      builder: (_) => RecipeDetailDialog(
        recipeId: recipe['id'] as String,
        onDeleted: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _limit).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rezept suchen…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Neueste')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _sort = v;
                      _page = 1;
                    });
                    _load();
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$_total Rezepte',
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
              : _recipes.isEmpty
                  ? const Center(child: Text('Keine Rezepte gefunden'))
                  : ListView.separated(
                      itemCount: _recipes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _recipes[index];
                        final createdAt = (r['created_at'] ?? '').toString();
                        final dateOnly = createdAt.length >= 10
                            ? createdAt.substring(0, 10)
                            : createdAt;
                        final isPublic = r['is_public'] == true;
                        return ListTile(
                          leading: _thumb(r['image_url'] as String?),
                          title: Text(
                            r['name'] ?? 'Unbekannt',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              Text(r['author_name'] ?? '?'),
                              const SizedBox(width: 8),
                              Text('•',
                                  style: TextStyle(color: Colors.grey[400])),
                              const SizedBox(width: 8),
                              Text(dateOnly,
                                  style:
                                      TextStyle(color: Colors.grey[700])),
                              const SizedBox(width: 8),
                              if (isPublic)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'öffentlich',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'privat',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _showPreview(r as Map),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteRecipe(
                              r['id'] as String,
                              r['name'] as String? ?? 'Rezept',
                            ),
                          ),
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

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.restaurant, color: Colors.white),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.restaurant, color: Colors.white),
        ),
      ),
    );
  }
}
