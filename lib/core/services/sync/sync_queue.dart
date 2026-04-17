import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'sync_operation.dart';

/// Persistent FIFO queue for sync operations. Backed by Hive.
/// Safe to access from anywhere; single process only.
class SyncQueue {
  static const _boxName = 'sync_outbox';
  static const _key = 'ops';

  Box get _box => Hive.box(_boxName);

  static Future<void> ensureOpen() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  List<SyncOperation> all() {
    final raw = _box.get(_key) as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .map((e) => SyncOperation.fromJson(
              Map<String, dynamic>.from(jsonDecode(e as String)),
            ))
        .toList();
  }

  Future<void> _persist(List<SyncOperation> ops) async {
    await _box.put(_key, ops.map((o) => jsonEncode(o.toJson())).toList());
  }

  Future<void> enqueue(SyncOperation op) async {
    final ops = all()..add(op);
    await _persist(ops);
  }

  Future<void> remove(String opId) async {
    final ops = all()..removeWhere((o) => o.id == opId);
    await _persist(ops);
  }

  Future<void> replace(String opId, SyncOperation updated) async {
    final ops = all();
    final idx = ops.indexWhere((o) => o.id == opId);
    if (idx >= 0) {
      ops[idx] = updated;
      await _persist(ops);
    }
  }

  Future<void> clear() async => _persist([]);

  int get length => all().length;
}
