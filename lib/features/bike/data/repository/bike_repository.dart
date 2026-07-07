import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/bike_create_request.dart';
import '../model/bike_response.dart';
import '../model/bike_update_request.dart';

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  return BikeRepository(ref.watch(dioProvider));
});

class BikeRepository {
  final Dio _dio;

  BikeRepository(this._dio);

  Future<List<BikeResponse>> getMyBikes() async {
    final response = await _dio.get('/bikes');
    final list = response.data['data'] as List;
    return list.map((e) => BikeResponse.fromJson(e)).toList();
  }

  Future<BikeResponse> getBike(String bikeId) async {
    final response = await _dio.get('/bikes/$bikeId');
    return BikeResponse.fromJson(response.data['data']);
  }

  Future<BikeResponse> createBike(BikeCreateRequest request) async {
    final response = await _dio.post('/bikes', data: request.toJson());
    return BikeResponse.fromJson(response.data['data']);
  }

  Future<BikeResponse> updateBike(String bikeId, BikeUpdateRequest request) async {
    final response = await _dio.put('/bikes/$bikeId', data: request.toJson());
    return BikeResponse.fromJson(response.data['data']);
  }

  Future<void> deleteBike(String bikeId) async {
    await _dio.delete('/bikes/$bikeId');
  }

  Future<BikeResponse> setRepresentative(String bikeId) async {
    final response = await _dio.patch('/bikes/$bikeId/representative');
    return BikeResponse.fromJson(response.data['data']);
  }

  /// 로컬 우선 sync 엔드포인트 (docs/sync-api.md 참조).
  /// upsert 방식: 서버가 request의 id를 그대로 수용, updated_at 비교로 LWW.
  /// deleted_at != null이면 soft delete 반영.
  Future<BikeResponse> sync(Map<String, Object?> body) async {
    final response = await _dio.post('/bikes/sync', data: body);
    return BikeResponse.fromJson(response.data['data']);
  }
}
