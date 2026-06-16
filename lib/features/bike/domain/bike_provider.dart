import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/bike_create_request.dart';
import '../data/model/bike_response.dart';
import '../data/model/bike_update_request.dart';
import '../data/repository/bike_repository.dart';

final bikeListProvider = AsyncNotifierProvider<BikeListNotifier, List<BikeResponse>>(
  BikeListNotifier.new,
);

class BikeListNotifier extends AsyncNotifier<List<BikeResponse>> {
  @override
  Future<List<BikeResponse>> build() async {
    return ref.watch(bikeRepositoryProvider).getMyBikes();
  }

  Future<void> create(BikeCreateRequest request) async {
    await ref.read(bikeRepositoryProvider).createBike(request);
    ref.invalidateSelf();
  }

  Future<void> updateBike(String bikeId, BikeUpdateRequest request) async {
    await ref.read(bikeRepositoryProvider).updateBike(bikeId, request);
    ref.invalidateSelf();
  }

  Future<void> delete(String bikeId) async {
    await ref.read(bikeRepositoryProvider).deleteBike(bikeId);
    ref.invalidateSelf();
  }

  Future<void> setRepresentative(String bikeId) async {
    await ref.read(bikeRepositoryProvider).setRepresentative(bikeId);
    ref.invalidateSelf();
  }
}
