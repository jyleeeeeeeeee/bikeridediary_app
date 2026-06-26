import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/avg_oil.dart';
import '../model/nearby_station.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.watch(dioProvider));
});

class StationRepository {
  final Dio _dio;

  StationRepository(this._dio);

  Future<List<AvgOil>> getAvgPrice() async {
    final response = await _dio.get('/stations/avg');
    final list = response.data['data'] as List;
    return list.map((e) => AvgOil.fromJson(e)).toList();
  }

  Future<List<NearbyStation>> searchNearby({
    required double lat,
    required double lng,
    int radius = 5000,
    String prodcd = 'B027',
    int sort = 1,
  }) async {
    final response = await _dio.get('/stations/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'prodcd': prodcd,
      'sort': sort,
    });
    final list = response.data['data'] as List;
    return list.map((e) => NearbyStation.fromJson(e)).toList();
  }
}
