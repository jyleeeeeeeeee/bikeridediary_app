import 'package:json_annotation/json_annotation.dart';

part 'maintenance_schedule_response.g.dart';

@JsonSerializable()
class MaintenanceScheduleResponse {
  final String id;
  final String bikeId;
  final String maintenanceType;
  final int? intervalKm;
  final int? intervalMonths;
  final int? lastMaintenanceMileage;
  final String? lastMaintenanceDate;
  final bool overdue;
  final String createdAt;
  final String? updatedAt;

  MaintenanceScheduleResponse({
    required this.id,
    required this.bikeId,
    required this.maintenanceType,
    this.intervalKm,
    this.intervalMonths,
    this.lastMaintenanceMileage,
    this.lastMaintenanceDate,
    required this.overdue,
    required this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleResponseFromJson(json);
}
