import 'package:json_annotation/json_annotation.dart';

part 'maintenance_schedule_create_request.g.dart';

@JsonSerializable()
class MaintenanceScheduleCreateRequest {
  final String bikeId;
  final String maintenanceType;
  final int? intervalKm;
  final int? intervalMonths;

  MaintenanceScheduleCreateRequest({
    required this.bikeId,
    required this.maintenanceType,
    this.intervalKm,
    this.intervalMonths,
  });

  Map<String, dynamic> toJson() => _$MaintenanceScheduleCreateRequestToJson(this);
}
