import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱 전역 네트워크 상태.
/// [ConnectivityResult.none]만 있는 경우 offline으로 판단.
class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  bool build() {
    _initListener();
    ref.onDispose(() => _sub?.cancel());
    // 초기값은 online 낙관 — 첫 스트림 이벤트 도착 시 갱신됨.
    _bootstrap();
    return true;
  }

  Future<void> _bootstrap() async {
    final initial = await Connectivity().checkConnectivity();
    state = _isOnline(initial);
  }

  void _initListener() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = _isOnline(results);
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}

/// true = 온라인, false = 오프라인.
final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
