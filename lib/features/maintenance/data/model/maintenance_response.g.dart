// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceResponse _$MaintenanceResponseFromJson(Map<String, dynamic> json) =>
    MaintenanceResponse(
      id: json['id'] as String,
      bikeId: json['bikeId'] as String,
      maintenanceType: json['maintenanceType'] as String,
      maintenanceDate: json['maintenanceDate'] as String,
      mileageAtMaintenance: (json['mileageAtMaintenance'] as num).toInt(),
      cost: (json['cost'] as num?)?.toInt(),
      description: json['description'] as String?,
      nextDueKm: (json['nextDueKm'] as num?)?.toInt(),
      nextDueDate: json['nextDueDate'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$MaintenanceResponseToJson(
  MaintenanceResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'bikeId': instance.bikeId,
  'maintenanceType': instance.maintenanceType,
  'maintenanceDate': instance.maintenanceDate,
  'mileageAtMaintenance': instance.mileageAtMaintenance,
  'cost': instance.cost,
  'description': instance.description,
  'nextDueKm': instance.nextDueKm,
  'nextDueDate': instance.nextDueDate,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
