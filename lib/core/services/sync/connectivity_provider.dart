import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  ConnectivityNotifier(this._connectivity) : super(true) {
    _init();
  }

  Future<void> _init() async {
    final res = await _connectivity.checkConnectivity();
    state = _hasConnection(res);
    _sub = _connectivity.onConnectivityChanged.listen((r) {
      final online = _hasConnection(r);
      if (state != online) state = online;
    });
  }

  bool _hasConnection(List<ConnectivityResult> r) {
    return r.any((c) =>
        c == ConnectivityResult.wifi ||
        c == ConnectivityResult.mobile ||
        c == ConnectivityResult.ethernet ||
        c == ConnectivityResult.vpn);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(Connectivity());
});
