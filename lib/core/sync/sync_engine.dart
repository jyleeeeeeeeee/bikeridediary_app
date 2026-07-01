import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_types.dart';

/// 도메인 sync 서비스들을 등록받아 일괄 처리하는 엔진.
///
/// 트리거:
/// - 앱 시작 시 1회 (main.dart에서 [startAutoSync] 호출)
/// - 네트워크 오프라인 → 온라인 전이 시 자동
/// - 각 도메인의 CRUD 성공 직후 fire-and-forget 호출 (선택)
/// - 유저의 pull-to-refresh 시 명시적 호출 (선택)
///
/// 도메인 등록: 각 도메인 provider가 앱 초기화 시점에 [register] 호출.
/// MVP 단계에선 등록된 도메인이 없어도 no-op으로 동작.
class SyncEngine {
  final List<Syncable> _services = [];
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isSyncing = false;
  bool _wasOnline = true;

  void register(Syncable service) {
    _services.add(service);
  }

  bool get hasServices => _services.isNotEmpty;

  /// 앱 시작 시점에 호출 — 초기 sync 시도 + 네트워크 리스너 등록.
  Future<void> startAutoSync() async {
    final initial = await Connectivity().checkConnectivity();
    _wasOnline = _isOnline(initial);

    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = _isOnline(results);
      // offline → online 전이 시에만 트리거 (online 상태 유지 중 재통지는 무시)
      if (online && !_wasOnline) {
        await syncAll();
      }
      _wasOnline = online;
    });

    if (_wasOnline) {
      await syncAll();
    }
  }

  Future<void> stopAutoSync() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  /// 등록된 모든 도메인 sync 실행. 재진입 방지 — 이미 실행 중이면 skip.
  /// 도메인 단위 예외는 삼킴 (Syncable 계약: throw 하지 않음).
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      for (final svc in _services) {
        try {
          await svc.syncPending();
        } catch (_) {
          // 도메인 내부에서 처리해야 하지만 실수로 새어나온 예외는 여기서 삼킴.
          // 다음 도메인으로 계속 진행.
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine();
  ref.onDispose(() => engine.stopAutoSync());
  return engine;
});
