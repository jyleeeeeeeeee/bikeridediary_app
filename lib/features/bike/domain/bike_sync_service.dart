import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_types.dart';
import '../data/local/bike_local_repository.dart';
import '../data/repository/bike_repository.dart';
import 'bike_provider.dart';

/// 바이크 도메인 sync 서비스.
///
/// 흐름:
/// 1. 로컬에서 sync_state IN ('PENDING', 'FAILED') 조회
/// 2. 각 레코드를 서버 upsert 엔드포인트로 전송 (POST /bikes/sync)
/// 3. deleted_at != null이면 soft delete → 성공 시 로컬 hard delete
/// 4. 실패는 markFailed로 저장, 다음 사이클에 재시도
/// 5. 결과 반영 후 bikeListProvider/bikeDetailProvider invalidate → UI가 최신 sync_state 표시
class BikeSyncService implements Syncable {
  final BikeLocalRepository _local;
  final BikeRepository _remote;
  final Ref _ref;

  BikeSyncService(this._local, this._remote, this._ref);

  @override
  String get name => 'bike';

  @override
  Future<void> syncPending() async {
    final pending = await _local.listPendingRaw();
    if (pending.isEmpty) return;
    for (final row in pending) {
      final id = row['id'] as String;
      final deletedAt = row['deleted_at'] as int?;
      try {
        await _remote.sync(_toSyncBody(row));
        if (deletedAt != null) {
          // soft delete가 서버에 반영됐으니 로컬은 정리
          await _local.hardDelete(id);
        } else {
          await _local.markSynced(id);
        }
      } on DioException catch (e) {
        await _local.markFailed(id, _errorMessage(e));
      } catch (e) {
        await _local.markFailed(id, e.toString());
      }
    }
    // UI가 최신 sync_state로 목록/상세를 다시 그리도록 invalidate.
    _ref.invalidate(bikeListProvider);
    _ref.invalidate(bikeDetailProvider);
  }

  /// 로그인 직후 최초 1회 호출 — 서버 데이터를 로컬로 pull.
  /// 로컬이 비어 있을 때만 실행하고, 이후는 sync만.
  Future<void> pullFromServerIfEmpty() async {
    final existing = await _local.listActive();
    if (existing.isNotEmpty) return;
    try {
      final serverBikes = await _remote.getMyBikes();
      for (final bike in serverBikes) {
        await _local.upsert(bike, state: SyncState.synced);
      }
      // pull된 데이터를 UI가 즉시 반영하도록 invalidate.
      // 이게 없으면 홈 화면이 pull보다 먼저 로컬을 조회해 빈 목록으로 굳음.
      _ref.invalidate(bikeListProvider);
    } catch (_) {
      // 오프라인이거나 서버 오류. 다음 sync 사이클에 재시도.
    }
  }

  Map<String, Object?> _toSyncBody(Map<String, Object?> row) {
    final createdAtMs = row['created_at'] as int;
    final updatedAtMs = row['updated_at'] as int;
    final deletedAtMs = row['deleted_at'] as int?;
    return {
      'id': row['id'],
      'manufacturerName': row['manufacturer_name'],
      'modelName': row['model_name'],
      'year': row['year'],
      'category': row['category'],
      'totalMileageKm': row['total_mileage_km'],
      'isRepresentative': (row['is_representative'] as int) == 1,
      'purchasedAt': row['purchased_at'],
      'photoUrl': row['photo_url'],
      'memo': row['memo'],
      'createdAt':
          DateTime.fromMillisecondsSinceEpoch(createdAtMs).toIso8601String(),
      'updatedAt':
          DateTime.fromMillisecondsSinceEpoch(updatedAtMs).toIso8601String(),
      'deletedAt': deletedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAtMs).toIso8601String(),
    };
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'Network error';
  }
}

final bikeLocalRepositoryProvider = Provider<BikeLocalRepository>((ref) {
  return BikeLocalRepository();
});

final bikeSyncServiceProvider = Provider<BikeSyncService>((ref) {
  return BikeSyncService(
    ref.watch(bikeLocalRepositoryProvider),
    ref.watch(bikeRepositoryProvider),
    ref,
  );
});
