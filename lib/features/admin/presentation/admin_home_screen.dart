import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/features/admin/providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          UploadTab(),
          DealsManagementTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Deals',
          ),
        ],
      ),
    );
  }
}

// Upload Tab
class UploadTab extends ConsumerStatefulWidget {
  const UploadTab({super.key});

  @override
  ConsumerState<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends ConsumerState<UploadTab> {
  File? _selectedFile;
  Supermarket? _selectedStore;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _resultMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _resultMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedStore == null) {
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
        file: _selectedFile!,
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
        _selectedFile = null;
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
                      _selectedFile == null
                          ? 'PDF oder Bild auswählen'
                          : _selectedFile!.path.split('/').last,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFile!.path.split('/').last,
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
