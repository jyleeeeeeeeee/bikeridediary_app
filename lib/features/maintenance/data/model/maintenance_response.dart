import 'package:json_annotation/json_annotation.dart';

part 'maintenance_response.g.dart';

@JsonSerializable()
class MaintenanceResponse {
  final String id;
  final String bikeId;
  final String maintenanceType;
  final String maintenanceDate;
  final int mileageAtMaintenance;
  final int? cost;
  final String? description;
  final int? nextDueKm;
  final String? nextDueDate;
  final String createdAt;
  final String? updatedAt;

  MaintenanceResponse({
    required this.id,
    required this.bikeId,
    required this.maintenanceType,
    required this.maintenanceDate,
    required this.mileageAtMaintenance,
    this.cost,
    this.description,
    this.nextDueKm,
    this.nextDueDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceResponse.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceResponseFromJson(json);
}
