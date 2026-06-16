import 'package:json_annotation/json_annotation.dart';

part 'maintenance_schedule_update_request.g.dart';

@JsonSerializable()
class MaintenanceScheduleUpdateRequest {
  final int? intervalKm;
  final int? intervalMonths;

  MaintenanceScheduleUpdateRequest({
    this.intervalKm,
    this.intervalMonths,
  });

  Map<String, dynamic> toJson() => _$MaintenanceScheduleUpdateRequestToJson(this);
}
