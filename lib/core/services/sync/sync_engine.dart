import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_provider.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// Drains the outbox to Supabase when online.
/// Call `flush()` explicitly or let it react to connectivity changes.
class SyncEngine {
  final SupabaseClient _client;
  final SyncQueue _queue;
  bool _running = false;
  Timer? _retryTimer;
  int _pendingCount = 0;

  /// Listener can subscribe to know when the queue depth changes (for UI badges).
  final _pendingController = StreamController<int>.broadcast();
  Stream<int> get pendingStream => _pendingController.stream;
  int get pending => _pendingCount;

  SyncEngine(this._client, this._queue) {
    _pendingCount = _queue.length;
  }

  Future<void> enqueue(SyncOperation op) async {
    await _queue.enqueue(op);
    _pendingCount = _queue.length;
    _pendingController.add(_pendingCount);
  }

  /// Try to push all queued operations to Supabase.
  /// Silent no-op if already running or offline.
  Future<void> flush({bool isOnline = true}) async {
    if (!isOnline || _running) return;
    _running = true;
    try {
      final ops = _queue.all();
      for (final op in ops) {
        final ok = await _apply(op);
        if (ok) {
          await _queue.remove(op.id);
        } else {
          final next = op.copyWith(attempts: op.attempts + 1);
          if (next.attempts > 5) {
            // Give up, drop — we log but don't retry forever.
            await _queue.remove(op.id);
          } else {
            await _queue.replace(op.id, next);
            _scheduleRetry();
            break;
          }
        }
      }
    } finally {
      _running = false;
      _pendingCount = _queue.length;
      _pendingController.add(_pendingCount);
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () => flush());
  }

  Future<bool> _apply(SyncOperation op) async {
    try {
      switch (op.op) {
        case SyncOpType.insert:
          if (op.data == null) return true;
          await _client.from(op.table).insert(op.data!);
          return true;
        case SyncOpType.update:
          if (op.data == null || op.rowId == null) return true;
          await _client.from(op.table).update(op.data!).eq('id', op.rowId!);
          return true;
        case SyncOpType.delete:
          if (op.rowId == null) return true;
          await _client.from(op.table).delete().eq('id', op.rowId!);
          return true;
      }
    } catch (e) {
      // Print for debugging. Will retry via attempts counter.
      // ignore: avoid_print
      print('Sync error [${op.op.name} ${op.table}]: $e');
      return false;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _pendingController.close();
  }
}

final syncQueueProvider = Provider<SyncQueue>((ref) => SyncQueue());

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    Supabase.instance.client,
    ref.watch(syncQueueProvider),
  );
  ref.listen<bool>(connectivityProvider, (_, online) {
    if (online) engine.flush(isOnline: true);
  }, fireImmediately: true);
  ref.onDispose(engine.dispose);
  return engine;
});

final pendingOpsCountProvider = StreamProvider<int>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.pendingStream.distinct();
});
