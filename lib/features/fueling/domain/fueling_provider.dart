import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/fueling_create_request.dart';
import '../data/model/fueling_response.dart';
import '../data/model/fueling_stats_response.dart';
import '../data/model/fueling_update_request.dart';
import '../data/repository/fueling_repository.dart';

// bikeId를 파라미터로 받아 해당 바이크의 주유 기록 목록을 관리
final fuelingListProvider =
    AsyncNotifierProvider.family<FuelingListNotifier, List<FuelingResponse>, String>(
  FuelingListNotifier.new,
);

class FuelingListNotifier extends FamilyAsyncNotifier<List<FuelingResponse>, String> {
  @override
  Future<List<FuelingResponse>> build(String arg) async {
    return ref.watch(fuelingRepositoryProvider).getFuelings(arg);
  }

  Future<void> createFueling(FuelingCreateRequest request) async {
    await ref.read(fuelingRepositoryProvider).createFueling(request);
    ref.invalidateSelf();
  }

  Future<void> updateFueling(String id, FuelingUpdateRequest request) async {
    await ref.read(fuelingRepositoryProvider).updateFueling(id, request);
    ref.invalidateSelf();
  }

  Future<void> deleteFueling(String id) async {
    await ref.read(fuelingRepositoryProvider).deleteFueling(id);
    ref.invalidateSelf();
  }
}

// 주유 통계 provider
final fuelingStatsProvider =
    FutureProvider.family<FuelingStatsResponse, String>((ref, bikeId) {
  return ref.watch(fuelingRepositoryProvider).getStats(bikeId);
});
