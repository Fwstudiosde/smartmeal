import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/family_provider.dart';

class FamilySettingsScreen extends ConsumerWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Haushalt')),
      body: state.isLoading && !state.hasFamily
          ? const Center(child: CircularProgressIndicator())
          : state.hasFamily
              ? _Member(state: state)
              : const _NoFamily(),
    );
  }
}

class _NoFamily extends ConsumerStatefulWidget {
  const _NoFamily();

  @override
  ConsumerState<_NoFamily> createState() => _NoFamilyState();
}

class _NoFamilyState extends ConsumerState<_NoFamily> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      await ref.read(familyProvider.notifier).createFamily(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _isJoining = true);
    try {
      await ref.read(familyProvider.notifier).joinByCode(code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Neuen Haushalt erstellen',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wochenplan + Einkaufsliste mit bis zu 6 Personen teilen.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name (z.B. Familie Müller)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _create,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Haushalt erstellen'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.login_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Mit Einladungscode beitreten',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code (z.B. ABCD-1234)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isJoining ? null : _join,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Beitreten'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Member extends ConsumerWidget {
  final FamilyState state;
  const _Member({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fam = state.family!;
    final currentUser = _currentUid();
    final iAmOwner = currentUser == fam.ownerId;

    return RefreshIndicator(
      onRefresh: () => ref.read(familyProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home,
                          color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fam.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (iAmOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Besitzer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Einladungscode',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            fam.inviteCode,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Kopieren',
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: fam.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code kopiert'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Teile diesen Code, damit andere beitreten können.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mitglieder',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${state.members.length} / ${fam.maxMembers}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...state.members.map((m) {
                    final isMe = m.userId == currentUser;
                    final displayName =
                        m.displayName ?? m.communityName ?? 'Unbekannt';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                      title: Text(
                        isMe ? '$displayName (Du)' : displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(m.isOwner ? 'Besitzer' : 'Mitglied'),
                      trailing: iAmOwner && !m.isOwner
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined,
                                  color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Mitglied entfernen?'),
                                    content: Text(
                                        '$displayName wird aus dem Haushalt entfernt.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Abbrechen'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Entfernen',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await ref
                                      .read(familyProvider.notifier)
                                      .removeMember(m.userId);
                                }
                              },
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(iAmOwner
                      ? 'Haushalt löschen?'
                      : 'Haushalt verlassen?'),
                  content: Text(iAmOwner
                      ? 'Der gesamte Haushalt wird für alle Mitglieder aufgelöst.'
                      : 'Du verlierst Zugriff auf geteilten Plan und Einkaufsliste.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(
                        iAmOwner ? 'Löschen' : 'Verlassen',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(familyProvider.notifier).leaveFamily();
              }
            },
            icon: Icon(iAmOwner ? Icons.delete_outline : Icons.logout,
                color: Colors.red),
            label: Text(
              iAmOwner ? 'Haushalt löschen' : 'Haushalt verlassen',
              style: const TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String? _currentUid() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
}
