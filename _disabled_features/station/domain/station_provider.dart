import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/model/avg_oil.dart';
import '../data/model/nearby_station.dart';
import '../data/repository/station_repository.dart';

final avgOilPriceProvider = FutureProvider<List<AvgOil>>((ref) {
  return ref.watch(stationRepositoryProvider).getAvgPrice();
});

final stationFuelTypeProvider = StateProvider<String>((ref) => 'B027');

final stationRadiusProvider = StateProvider<int>((ref) => 5000);

final stationSortProvider = StateProvider<int>((ref) => 1);

final nearbyStationsProvider =
    AsyncNotifierProvider<NearbyStationsNotifier, List<NearbyStation>>(
  NearbyStationsNotifier.new,
);

class NearbyStationsNotifier extends AsyncNotifier<List<NearbyStation>> {
  @override
  Future<List<NearbyStation>> build() async {
    return [];
  }

  Future<void> search() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final permission = await _ensureLocationPermission();
      if (!permission) throw Exception('위치 권한이 필요합니다.');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final fuelType = ref.read(stationFuelTypeProvider);
      final radius = ref.read(stationRadiusProvider);
      final sort = ref.read(stationSortProvider);

      return ref.read(stationRepositoryProvider).searchNearby(
            lat: position.latitude,
            lng: position.longitude,
            radius: radius,
            prodcd: fuelType,
            sort: sort,
          );
    });
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
