import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';
import 'package:smartmeal/features/admin/presentation/recipe_detail_dialog.dart';
import 'package:smartmeal/features/admin/presentation/user_detail_dialog.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _timeseries;
  Map<String, dynamic>? _top;
  Map<String, dynamic>? _health;
  List<dynamic>? _moderationQueue;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(adminApiClientProvider);
      final results = await Future.wait([
        api.getStatsOverview(),
        api.getStatsTimeseries(days: 30),
        api.getStatsTop(),
        api.getModerationQueue(limit: 10),
        api.getHealth(),
      ]);

      setState(() {
        _overview = results[0];
        _timeseries = results[1];
        _top = results[2];
        _moderationQueue = results[3]['recipes'] as List<dynamic>;
        _health = results[4];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecipe(String id) async {
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
      _loadAll();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHealthBar(),
          const SizedBox(height: 16),
          _buildKpiGrid(),
          const SizedBox(height: 24),
          _buildChart(
            'Neuanmeldungen (30 Tage)',
            (_timeseries?['signups'] as List<dynamic>?) ?? [],
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildChart(
            'Community-Rezepte (30 Tage)',
            (_timeseries?['recipes'] as List<dynamic>?) ?? [],
            Colors.green,
          ),
          const SizedBox(height: 24),
          _buildDealsByStore(),
          const SizedBox(height: 24),
          _buildTopRecipes(),
          const SizedBox(height: 16),
          _buildTopAuthors(),
          const SizedBox(height: 24),
          _buildModerationQueue(),
        ],
      ),
    );
  }

  Widget _buildHealthBar() {
    final ok = _health?['supabase'] == 'ok';
    final latency = _health?['supabase_latency_ms'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? Colors.green[300]! : Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error,
            color: ok ? Colors.green[700] : Colors.red[700],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            ok
                ? 'System OK • Supabase ${latency}ms'
                : 'Supabase offline!',
            style: TextStyle(
              color: ok ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Aktualisiert: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final users = _overview?['users'] as Map? ?? {};
    final recipes = _overview?['recipes'] as Map? ?? {};
    final deals = _overview?['deals'] as Map? ?? {};
    final engagement = _overview?['engagement'] as Map? ?? {};

    final engagementSum = (engagement['likes_week'] as int? ?? 0) +
        (engagement['follows_week'] as int? ?? 0) +
        (engagement['bookmarks_week'] as int? ?? 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final crossAxisCount = isWide ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _kpiCard(
              icon: Icons.people_outline,
              label: 'Nutzer gesamt',
              value: '${users['total'] ?? 0}',
              delta: '+${users['new_week'] ?? 0} / Woche',
              color: Colors.blue,
            ),
            _kpiCard(
              icon: Icons.restaurant_menu,
              label: 'Community-Rezepte',
              value: '${recipes['total_community'] ?? 0}',
              delta: '+${recipes['new_week'] ?? 0} / Woche',
              color: Colors.green,
            ),
            _kpiCard(
              icon: Icons.local_offer_outlined,
              label: 'Aktive Deals',
              value: '${deals['active'] ?? 0}',
              delta: '${deals['total'] ?? 0} gesamt',
              color: Colors.orange,
            ),
            _kpiCard(
              icon: Icons.favorite_outline,
              label: 'Engagement (7d)',
              value: '$engagementSum',
              delta:
                  '${engagement['likes_week'] ?? 0}♥ ${engagement['follows_week'] ?? 0}👤',
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String label,
    required String value,
    required String delta,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              delta,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, List<dynamic> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final count = (data[i]['count'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), count));
    }

    final maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: (maxY < 5 ? 5 : maxY * 1.2),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (data.length / 5).ceilToDouble(),
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = data[idx]['date']?.toString() ?? '';
                          if (dateStr.length < 10) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${dateStr.substring(8, 10)}.${dateStr.substring(5, 7)}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsByStore() {
    final byStore = (_overview?['deals'] as Map?)?['by_store'] as Map? ?? {};
    if (byStore.isEmpty) return const SizedBox.shrink();

    final entries = byStore.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktive Deals pro Supermarkt',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) {
              final total = entries.fold<int>(0, (s, x) => s + (x.value as int));
              final pct = total == 0 ? 0.0 : (e.value as int) / total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(e.key.toString(),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRecipes() {
    final list = (_top?['top_recipes'] as List<dynamic>?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Rezepte (7 Tage)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...list.map((r) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: _recipeThumb(r['image_url'] as String?),
                title: Text(
                  r['name'] ?? 'Unbekannt',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(r['author_name'] ?? ''),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => RecipeDetailDialog(
                    recipeId: r['id'] as String,
                    onDeleted: _loadAll,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text('${r['likes_week']}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAuthors() {
    final list = (_top?['top_authors'] as List<dynamic>?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Autoren',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...list.map((a) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    (a['display_name'] ?? a['community_name'] ?? '?')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                title: Text(
                  a['display_name'] ?? a['community_name'] ?? 'Unbekannt',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => UserDetailDialog(
                    userId: a['id'] as String,
                    onDeleted: _loadAll,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14),
                    const SizedBox(width: 4),
                    Text('${a['followers']}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationQueue() {
    final list = _moderationQueue ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Moderations-Queue',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${list.length} neue',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(),
            ...list.map((r) {
              final id = r['id']?.toString() ?? '';
              final createdAt = (r['created_at'] ?? '').toString();
              final dateOnly = createdAt.length >= 10
                  ? createdAt.substring(0, 10)
                  : createdAt;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _recipeThumb(r['image_url'] as String?),
                title: Text(
                  r['name'] ?? 'Unbekannt',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${r['author_name'] ?? '?'} • $dateOnly'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => RecipeDetailDialog(
                    recipeId: id,
                    onDeleted: _loadAll,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Rezept löschen?'),
                      content: Text(
                          '${r['name']} wird endgültig entfernt.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteRecipe(id);
                          },
                          child: const Text(
                            'Löschen',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _recipeThumb(String? url) {
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
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.restaurant, color: Colors.white),
        ),
      ),
    );
  }
}
