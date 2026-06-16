import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/maintenance_create_request.dart';
import '../data/model/maintenance_response.dart';
import '../data/model/maintenance_schedule_create_request.dart';
import '../data/model/maintenance_schedule_response.dart';
import '../data/model/maintenance_schedule_update_request.dart';
import '../data/model/maintenance_update_request.dart';
import '../data/repository/maintenance_repository.dart';

// bikeId를 파라미터로 받아 해당 바이크의 정비 기록 목록을 관리
final maintenanceListProvider =
    AsyncNotifierProvider.family<MaintenanceListNotifier, List<MaintenanceResponse>, String>(
  MaintenanceListNotifier.new,
);

class MaintenanceListNotifier extends FamilyAsyncNotifier<List<MaintenanceResponse>, String> {
  @override
  Future<List<MaintenanceResponse>> build(String arg) async {
    return ref.watch(maintenanceRepositoryProvider).getMaintenances(arg);
  }

  Future<void> createMaintenance(MaintenanceCreateRequest request) async {
    await ref.read(maintenanceRepositoryProvider).createMaintenance(request);
    ref.invalidateSelf();
  }

  Future<void> updateMaintenance(String id, MaintenanceUpdateRequest request) async {
    await ref.read(maintenanceRepositoryProvider).updateMaintenance(id, request);
    ref.invalidateSelf();
  }

  Future<void> deleteMaintenance(String id) async {
    await ref.read(maintenanceRepositoryProvider).deleteMaintenance(id);
    ref.invalidateSelf();
  }
}

// 정비 스케줄
final scheduleListProvider =
    AsyncNotifierProvider.family<ScheduleListNotifier, List<MaintenanceScheduleResponse>, String>(
  ScheduleListNotifier.new,
);

class ScheduleListNotifier extends FamilyAsyncNotifier<List<MaintenanceScheduleResponse>, String> {
  @override
  Future<List<MaintenanceScheduleResponse>> build(String arg) async {
    return ref.watch(maintenanceRepositoryProvider).getSchedules(arg);
  }

  Future<void> createSchedule(MaintenanceScheduleCreateRequest request) async {
    await ref.read(maintenanceRepositoryProvider).createSchedule(request);
    ref.invalidateSelf();
  }

  Future<void> updateSchedule(String id, MaintenanceScheduleUpdateRequest request) async {
    await ref.read(maintenanceRepositoryProvider).updateSchedule(id, request);
    ref.invalidateSelf();
  }

  Future<void> deleteSchedule(String id) async {
    await ref.read(maintenanceRepositoryProvider).deleteSchedule(id);
    ref.invalidateSelf();
  }
}
