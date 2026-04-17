import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';
import 'package:smartmeal/features/admin/presentation/dashboard_tab.dart';
import 'package:smartmeal/features/admin/presentation/users_tab.dart';
import 'package:smartmeal/features/admin/presentation/moderation_tab.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    _AdminTab(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _AdminTab(icon: Icons.people_outline, label: 'Users'),
    _AdminTab(icon: Icons.shield_outlined, label: 'Moderation'),
    _AdminTab(icon: Icons.upload_file, label: 'Upload'),
    _AdminTab(icon: Icons.local_offer_outlined, label: 'Deals'),
    _AdminTab(icon: Icons.archive_outlined, label: 'Archiv'),
  ];

  static const _tabBodies = [
    DashboardTab(),
    UsersTab(),
    ModerationTab(),
    UploadTab(),
    DealsManagementTab(),
    ArchiveTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SparKoch Admin'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                authState.username ?? 'Admin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 800;
          if (wide) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  destinations: _tabs
                      .map(
                        (t) => NavigationRailDestination(
                          icon: Icon(t.icon),
                          label: Text(t.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _tabBodies,
                  ),
                ),
              ],
            );
          }
          return IndexedStack(
            index: _selectedIndex,
            children: _tabBodies,
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.of(context).size.width > 800) {
            return const SizedBox.shrink();
          }
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: _tabs
                .map(
                  (t) => NavigationDestination(
                    icon: Icon(t.icon),
                    label: t.label,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _AdminTab {
  final IconData icon;
  final String label;
  const _AdminTab({required this.icon, required this.label});
}

// Upload Tab
class UploadTab extends ConsumerStatefulWidget {
  const UploadTab({super.key});

  @override
  ConsumerState<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends ConsumerState<UploadTab> {
  Uint8List? _selectedBytes;
  String? _selectedFilename;
  Supermarket? _selectedStore;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _resultMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedBytes = result.files.single.bytes;
        _selectedFilename = result.files.single.name;
        _resultMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedBytes == null || _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Datei und Supermarkt auswählen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _resultMessage = null;
    });

    try {
      final apiClient = ref.read(adminApiClientProvider);
      final result = await apiClient.uploadProspekt(
        bytes: _selectedBytes!,
        filename: _selectedFilename!,
        storeName: _selectedStore!.name,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _isUploading = false;
        if (result['status'] == 'processing') {
          _resultMessage =
              '✅ ${result['message']}\n\n${result['note'] ?? ''}';
        } else {
          _resultMessage =
              '✅ ${result['deals_count'] ?? 0} Angebote erfolgreich extrahiert!';
        }
        _selectedBytes = null;
        _selectedFilename = null;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Upload erfolgreich'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _resultMessage = '❌ Fehler: $e';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Prospekt hochladen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Store selection
                  const Text(
                    'Supermarkt',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStore?.name,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Supermarkt auswählen'),
                    items: Supermarket.all.map((store) {
                      return DropdownMenuItem<String>(
                        value: store.name,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStore = Supermarket.all.firstWhere(
                          (s) => s.name == value,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // File picker
                  const Text(
                    'Datei',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _selectedFilename ?? 'PDF oder Bild auswählen',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  if (_selectedFilename != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFilename!,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Upload button
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadFile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          )
                        : const Text(
                            'Hochladen & Analysieren',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  // Result message
                  if (_resultMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _resultMessage!.startsWith('✅')
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _resultMessage!.startsWith('✅')
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Help card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tipps',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• PDF-Prospekte oder Screenshots verwenden\n'
                    '• Gute Bildqualität = bessere Erkennung\n'
                    '• Angebote werden automatisch extrahiert\n'
                    '• Preise, Rabatte und Zeiträume werden erkannt',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Deals Management Tab
class DealsManagementTab extends ConsumerStatefulWidget {
  const DealsManagementTab({super.key});

  @override
  ConsumerState<DealsManagementTab> createState() =>
      _DealsManagementTabState();
}

class _DealsManagementTabState extends ConsumerState<DealsManagementTab> {
  List<dynamic>? _deals;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(adminApiClientProvider);
      final result = await apiClient.getAllDeals();

      setState(() {
        _deals = result['deals'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDeal(int index) async {
    try {
      final apiClient = ref.read(adminApiClientProvider);
      await apiClient.deleteDeal(index);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadDeals();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
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

    if (_deals == null || _deals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Deals vorhanden',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lade ein Prospekt hoch um zu starten',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_deals!.length} Deals',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDeals,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _deals!.length,
            itemBuilder: (context, index) {
              final deal = _deals![index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  title: Text(
                    deal['product_name'] ?? 'Unbekannt',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${deal['store_name']} • ${deal['category']}'),
                      Text(
                        '${deal['discount_price']}€ (${deal['discount_percentage']}% Rabatt)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Deal löschen?'),
                          content: const Text(
                            'Möchtest du diesen Deal wirklich löschen?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteDeal(index);
                              },
                              child: const Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Archive Tab - deals grouped by ISO week → supermarket
class ArchiveTab extends ConsumerStatefulWidget {
  const ArchiveTab({super.key});

  @override
  ConsumerState<ArchiveTab> createState() => _ArchiveTabState();
}

class _ArchiveTabState extends ConsumerState<ArchiveTab> {
  List<dynamic>? _deals;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(adminApiClientProvider);
      final result = await apiClient.getAllDeals();
      setState(() {
        _deals = result['deals'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ISO 8601 week number
  static int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: 4 - (date.weekday)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekThursday = firstThursday.add(
      Duration(days: 4 - firstThursday.weekday),
    );
    return 1 + (thursday.difference(firstWeekThursday).inDays ~/ 7);
  }

  static int _isoWeekYear(DateTime date) {
    final thursday = date.add(Duration(days: 4 - (date.weekday)));
    return thursday.year;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deals == null || _deals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Keine Angebote im Archiv',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group: weekKey (year-week) → storeName → deals
    final Map<String, Map<String, List<dynamic>>> grouped = {};
    final Map<String, DateTime> weekSortKey = {};

    for (final deal in _deals!) {
      final date = _parseDate(deal['valid_from']) ??
          _parseDate(deal['valid_until']) ??
          DateTime.now();
      final year = _isoWeekYear(date);
      final week = _isoWeek(date);
      final key = '$year-${week.toString().padLeft(2, '0')}';
      weekSortKey[key] = date;

      final store = (deal['store_name'] ?? 'Unbekannt').toString();
      grouped.putIfAbsent(key, () => {});
      grouped[key]!.putIfAbsent(store, () => []);
      grouped[key]![store]!.add(deal);
    }

    // Sort weeks descending (newest first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadDeals,
      child: ListView.builder(
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final parts = key.split('-');
          final year = parts[0];
          final week = int.parse(parts[1]);
          final stores = grouped[key]!;
          final totalDeals = stores.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Text(
                  'KW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                'KW $week / $year',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$totalDeals Angebote • ${stores.length} Supermärkte',
              ),
              children: stores.entries.map((entry) {
                final store = entry.key;
                final storeDeals = entry.value;
                return ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: const Icon(Icons.store_outlined),
                  title: Text(
                    store,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${storeDeals.length} Angebote'),
                  children: storeDeals.map((deal) {
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 56, right: 16),
                      dense: true,
                      title: Text(
                        deal['product_name'] ?? 'Unbekannt',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${deal['discount_price']}€'
                        '${deal['discount_percentage'] != null ? ' (${deal['discount_percentage']}% Rabatt)' : ''}'
                        '${deal['category'] != null ? ' • ${deal['category']}' : ''}',
                      ),
                      trailing: Text(
                        _formatDateRange(deal),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  String _formatDateRange(dynamic deal) {
    final from = _parseDate(deal['valid_from']);
    final until = _parseDate(deal['valid_until']);
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    if (from != null && until != null) return '${fmt(from)}–${fmt(until)}';
    if (from != null) return 'ab ${fmt(from)}';
    if (until != null) return 'bis ${fmt(until)}';
    return '';
  }
}
