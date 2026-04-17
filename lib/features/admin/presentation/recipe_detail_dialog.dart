import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';

class RecipeDetailDialog extends ConsumerStatefulWidget {
  final String recipeId;
  final VoidCallback? onDeleted;

  const RecipeDetailDialog({
    super.key,
    required this.recipeId,
    this.onDeleted,
  });

  @override
  ConsumerState<RecipeDetailDialog> createState() =>
      _RecipeDetailDialogState();
}

class _RecipeDetailDialogState extends ConsumerState<RecipeDetailDialog> {
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
          .getRecipeDetail(widget.recipeId);
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

  Future<void> _delete() async {
    final recipe = _data?['recipe'] as Map?;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: Text(
          '${recipe?['name'] ?? 'Rezept'} wird endgültig entfernt.',
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
      await ref
          .read(adminApiClientProvider)
          .deleteCommunityRecipe(widget.recipeId);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezept gelöscht'),
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
    final recipe = _data!['recipe'] as Map;
    final author = _data!['author'] as Map?;
    final likes = _data!['likes'] as int? ?? 0;
    final saves = _data!['saves'] as int? ?? 0;
    final ingredients = recipe['ingredients'];
    final instructions = recipe['instructions'];
    final imageUrl = recipe['image_url'] as String?;
    final createdAt = (recipe['created_at'] ?? '').toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'] ?? 'Unbekannt',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'von ${recipe['author_name'] ?? author?['display_name'] ?? '?'}'
                      '${author?['email'] != null ? ' • ${author!['email']}' : ''}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaChips(recipe, likes, saves),
                const SizedBox(height: 16),
                if ((recipe['description'] as String?)?.isNotEmpty == true) ...[
                  _sectionTitle('Beschreibung'),
                  Text(recipe['description']),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Zutaten'),
                _ingredientsList(ingredients),
                const SizedBox(height: 16),
                _sectionTitle('Zubereitung'),
                _instructionsList(instructions),
                const SizedBox(height: 16),
                _sectionTitle('Meta'),
                _metaRow('Rezept-ID', recipe['id']?.toString() ?? ''),
                _metaRow('User-ID', recipe['user_id']?.toString() ?? ''),
                _metaRow(
                  'Sichtbarkeit',
                  recipe['is_public'] == true ? 'Öffentlich' : 'Privat',
                ),
                _metaRow(
                  'Erstellt',
                  createdAt.isEmpty ? '–' : createdAt.substring(0, 19),
                ),
                const SizedBox(height: 16),
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
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Rezept löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );

  Widget _metaChips(Map recipe, int likes, int saves) {
    final items = <(IconData, String)>[
      if (recipe['prep_time'] != null)
        (Icons.schedule, 'Vorb. ${recipe['prep_time']} min'),
      if (recipe['cook_time'] != null)
        (Icons.timer_outlined, 'Kochen ${recipe['cook_time']} min'),
      if (recipe['servings'] != null)
        (Icons.people_outline, '${recipe['servings']} Port.'),
      if (recipe['difficulty'] != null)
        (Icons.trending_up, '${recipe['difficulty']}'),
      (Icons.favorite_outline, '$likes Likes'),
      (Icons.bookmark_outline, '$saves Saves'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) {
        return Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(i.$1, size: 14),
          label: Text(i.$2, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }

  Widget _ingredientsList(dynamic raw) {
    final List list = raw is List ? raw : const [];
    if (list.isEmpty) {
      return Text('(keine Zutaten)', style: TextStyle(color: Colors.grey[600]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((ing) {
        String text;
        if (ing is Map) {
          final name = ing['name'] ?? ing['ingredient_name'] ?? '?';
          final qty = ing['quantity'] ?? ing['amount'];
          final unit = ing['unit'] ?? '';
          text = qty != null ? '$qty $unit $name'.trim() : name.toString();
        } else {
          text = ing.toString();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(text)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _instructionsList(dynamic raw) {
    final List list = raw is List ? raw : const [];
    if (list.isEmpty) {
      return Text('(keine Anleitung)', style: TextStyle(color: Colors.grey[600]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(list.length, (i) {
        final step = list[i];
        final text = step is Map
            ? (step['instruction'] ?? step['text'] ?? '').toString()
            : step.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        );
      }),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
