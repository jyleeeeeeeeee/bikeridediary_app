import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/local/bike_local_repository.dart';
import '../data/model/bike_create_request.dart';
import '../data/model/bike_response.dart';
import '../data/model/bike_update_request.dart';
import 'bike_sync_service.dart';

const _uuid = Uuid();

final bikeDetailProvider = FutureProvider.family<BikeResponse, String>((ref, bikeId) async {
  final local = ref.watch(bikeLocalRepositoryProvider);
  final bike = await local.find(bikeId);
  if (bike == null) {
    throw StateError('Bike not found: $bikeId');
  }
  return bike;
});

final bikeListProvider = AsyncNotifierProvider<BikeListNotifier, List<BikeResponse>>(
  BikeListNotifier.new,
);

/// 로컬 우선 바이크 리스트.
/// 모든 CRUD는 로컬 SQLite에 즉시 반영 후 SyncEngine을 fire-and-forget으로 트리거.
/// 로컬 게스트는 sync 자체가 skip되므로 서버 통신 없이 완전 동작.
class BikeListNotifier extends AsyncNotifier<List<BikeResponse>> {
  BikeLocalRepository get _local => ref.read(bikeLocalRepositoryProvider);

  @override
  Future<List<BikeResponse>> build() async {
    return _local.listActive();
  }

  Future<void> create(BikeCreateRequest request) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final bike = BikeResponse(
      id: id,
      manufacturerName: request.manufacturerName,
      modelName: request.modelName,
      year: request.year,
      category: request.category,
      totalMileageKm: request.totalMileageKm,
      isRepresentative: false,
      createdAt: now.toIso8601String(),
    );
    await _local.upsert(bike);
    ref.invalidateSelf();
    _triggerSync();
  }

  Future<void> updateBike(String bikeId, BikeUpdateRequest request) async {
    await _local.updateFields(bikeId, {
      'manufacturer_name': request.manufacturerName,
      'model_name': request.modelName,
      'year': request.year,
      'category': request.category,
      'total_mileage_km': request.totalMileageKm,
      'purchased_at': request.purchasedAt,
      'memo': request.memo,
    });
    ref.invalidateSelf();
    ref.invalidate(bikeDetailProvider(bikeId));
    _triggerSync();
  }

  Future<void> delete(String bikeId) async {
    await _local.softDelete(bikeId);
    ref.invalidateSelf();
    ref.invalidate(bikeDetailProvider(bikeId));
    _triggerSync();
  }

  Future<void> setRepresentative(String bikeId) async {
    await _local.setRepresentative(bikeId);
    ref.invalidateSelf();
    ref.invalidate(bikeDetailProvider(bikeId));
    _triggerSync();
  }

  /// 서버 sync는 로컬 게스트가 아니고 sync engine에 등록된 서비스가 있을 때만.
  /// 실패해도 sync engine이 다음 사이클에 재시도.
  void _triggerSync() {
    final auth = ref.read(authProvider);
    if (auth.isLocalGuest) return;
    // fire-and-forget — 결과를 기다리지 않음.
    // 실패해도 다음 온라인 전이/앱 재시작 시 자동 재시도.
    ref.read(syncEngineProvider).syncAll();
  }
}
