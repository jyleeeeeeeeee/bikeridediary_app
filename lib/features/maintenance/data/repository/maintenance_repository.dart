import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/maintenance_create_request.dart';
import '../model/maintenance_response.dart';
import '../model/maintenance_schedule_create_request.dart';
import '../model/maintenance_schedule_response.dart';
import '../model/maintenance_schedule_update_request.dart';
import '../model/maintenance_update_request.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.watch(dioProvider));
});

class MaintenanceRepository {
  final Dio _dio;

  MaintenanceRepository(this._dio);

  // 정비 기록
  Future<List<MaintenanceResponse>> getMaintenances(String bikeId) async {
    final response = await _dio.get('/maintenances', queryParameters: {'bikeId': bikeId});
    final list = response.data['data'] as List;
    return list.map((e) => MaintenanceResponse.fromJson(e)).toList();
  }

  Future<MaintenanceResponse> getMaintenance(String id) async {
    final response = await _dio.get('/maintenances/$id');
    return MaintenanceResponse.fromJson(response.data['data']);
  }

  Future<MaintenanceResponse> createMaintenance(MaintenanceCreateRequest request) async {
    final response = await _dio.post('/maintenances', data: request.toJson());
    return MaintenanceResponse.fromJson(response.data['data']);
  }

  Future<MaintenanceResponse> updateMaintenance(String id, MaintenanceUpdateRequest request) async {
    final response = await _dio.put('/maintenances/$id', data: request.toJson());
    return MaintenanceResponse.fromJson(response.data['data']);
  }

  Future<void> deleteMaintenance(String id) async {
    await _dio.delete('/maintenances/$id');
  }

  // 정비 스케줄
  Future<List<MaintenanceScheduleResponse>> getSchedules(String bikeId) async {
    final response = await _dio.get('/maintenance-schedules', queryParameters: {'bikeId': bikeId});
    final list = response.data['data'] as List;
    return list.map((e) => MaintenanceScheduleResponse.fromJson(e)).toList();
  }

  Future<MaintenanceScheduleResponse> createSchedule(MaintenanceScheduleCreateRequest request) async {
    final response = await _dio.post('/maintenance-schedules', data: request.toJson());
    return MaintenanceScheduleResponse.fromJson(response.data['data']);
  }

  Future<MaintenanceScheduleResponse> updateSchedule(String id, MaintenanceScheduleUpdateRequest request) async {
    final response = await _dio.put('/maintenance-schedules/$id', data: request.toJson());
    return MaintenanceScheduleResponse.fromJson(response.data['data']);
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete('/maintenance-schedules/$id');
  }
}
