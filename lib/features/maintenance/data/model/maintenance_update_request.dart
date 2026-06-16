import 'package:json_annotation/json_annotation.dart';

part 'maintenance_update_request.g.dart';

@JsonSerializable()
class MaintenanceUpdateRequest {
  final String maintenanceType;
  final String maintenanceDate;
  final int mileageAtMaintenance;
  final int? cost;
  final String? description;
  final int? nextDueKm;
  final String? nextDueDate;

  MaintenanceUpdateRequest({
    required this.maintenanceType,
    required this.maintenanceDate,
    required this.mileageAtMaintenance,
    this.cost,
    this.description,
    this.nextDueKm,
    this.nextDueDate,
  });

  Map<String, dynamic> toJson() => _$MaintenanceUpdateRequestToJson(this);
}
