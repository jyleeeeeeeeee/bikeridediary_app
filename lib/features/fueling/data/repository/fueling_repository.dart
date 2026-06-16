import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/fueling_create_request.dart';
import '../model/fueling_response.dart';
import '../model/fueling_stats_response.dart';
import '../model/fueling_update_request.dart';

final fuelingRepositoryProvider = Provider<FuelingRepository>((ref) {
  return FuelingRepository(ref.watch(dioProvider));
});

class FuelingRepository {
  final Dio _dio;

  FuelingRepository(this._dio);

  Future<List<FuelingResponse>> getFuelings(String bikeId) async {
    final response = await _dio.get('/fuelings', queryParameters: {'bikeId': bikeId});
    final list = response.data['data'] as List;
    return list.map((e) => FuelingResponse.fromJson(e)).toList();
  }

  Future<FuelingResponse> getFueling(String id) async {
    final response = await _dio.get('/fuelings/$id');
    return FuelingResponse.fromJson(response.data['data']);
  }

  Future<FuelingResponse> createFueling(FuelingCreateRequest request) async {
    final response = await _dio.post('/fuelings', data: request.toJson());
    return FuelingResponse.fromJson(response.data['data']);
  }

  Future<FuelingResponse> updateFueling(String id, FuelingUpdateRequest request) async {
    final response = await _dio.put('/fuelings/$id', data: request.toJson());
    return FuelingResponse.fromJson(response.data['data']);
  }

  Future<void> deleteFueling(String id) async {
    await _dio.delete('/fuelings/$id');
  }

  Future<FuelingStatsResponse> getStats(String bikeId) async {
    final response = await _dio.get('/fuelings/stats', queryParameters: {'bikeId': bikeId});
    return FuelingStatsResponse.fromJson(response.data['data']);
  }
}
