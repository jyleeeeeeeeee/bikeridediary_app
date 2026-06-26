import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/maintenance_create_request.dart';
import '../data/model/maintenance_response.dart';
import '../data/model/maintenance_schedule_create_request.dart';
import '../data/model/maintenance_schedule_response.dart';
import '../data/model/maintenance_schedule_update_request.dart';
import '../data/model/maintenance_update_request.dart';
import '../data/repository/maintenance_repository.dart';

final maintenanceDetailProvider =
    FutureProvider.family<MaintenanceResponse, String>((ref, id) {
  return ref.watch(maintenanceRepositoryProvider).getMaintenance(id);
});

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

  Future<void> createMaintenance(MaintenanceCreateRequest request, {List<File>? images}) async {
    await ref.read(maintenanceRepositoryProvider).createMaintenance(request, images: images);
    ref.invalidateSelf();
    ref.invalidate(bikeListProvider);
    ref.invalidate(bikeDetailProvider(arg));
    ref.invalidate(scheduleListProvider(arg));
  }

  Future<void> updateMaintenance(
    String id,
    MaintenanceUpdateRequest request, {
    List<File>? newImages,
    List<String>? existingImageUrls,
  }) async {
    await ref.read(maintenanceRepositoryProvider).updateMaintenance(
      id, request,
      newImages: newImages,
      existingImageUrls: existingImageUrls,
    );
    ref.invalidateSelf();
    ref.invalidate(maintenanceDetailProvider(id));
    ref.invalidate(bikeListProvider);
    ref.invalidate(bikeDetailProvider(arg));
    ref.invalidate(scheduleListProvider(arg));
  }

  Future<void> deleteMaintenance(String id) async {
    await ref.read(maintenanceRepositoryProvider).deleteMaintenance(id);
    ref.invalidateSelf();
    ref.invalidate(maintenanceDetailProvider(id));
    ref.invalidate(bikeListProvider);
    ref.invalidate(bikeDetailProvider(arg));
    ref.invalidate(scheduleListProvider(arg));
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
