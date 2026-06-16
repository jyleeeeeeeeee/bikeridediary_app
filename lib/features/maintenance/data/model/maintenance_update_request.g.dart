// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceUpdateRequest _$MaintenanceUpdateRequestFromJson(
  Map<String, dynamic> json,
) => MaintenanceUpdateRequest(
  maintenanceType: json['maintenanceType'] as String,
  maintenanceDate: json['maintenanceDate'] as String,
  mileageAtMaintenance: (json['mileageAtMaintenance'] as num).toInt(),
  cost: (json['cost'] as num?)?.toInt(),
  description: json['description'] as String?,
  nextDueKm: (json['nextDueKm'] as num?)?.toInt(),
  nextDueDate: json['nextDueDate'] as String?,
);

Map<String, dynamic> _$MaintenanceUpdateRequestToJson(
  MaintenanceUpdateRequest instance,
) => <String, dynamic>{
  'maintenanceType': instance.maintenanceType,
  'maintenanceDate': instance.maintenanceDate,
  'mileageAtMaintenance': instance.mileageAtMaintenance,
  'cost': instance.cost,
  'description': instance.description,
  'nextDueKm': instance.nextDueKm,
  'nextDueDate': instance.nextDueDate,
};
