import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/nearby_station.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.watch(dioProvider));
});

class StationRepository {
  final Dio _dio;

  StationRepository(this._dio);

  Future<List<NearbyStation>> searchNearby({
    required double lat,
    required double lng,
    int radius = 5000,
    String prodcd = 'B027',
  }) async {
    final response = await _dio.get('/stations/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'prodcd': prodcd,
    });
    final list = response.data['data'] as List;
    return list.map((e) => NearbyStation.fromJson(e)).toList();
  }
}
