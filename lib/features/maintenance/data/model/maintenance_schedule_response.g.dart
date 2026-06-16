// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_schedule_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceScheduleResponse _$MaintenanceScheduleResponseFromJson(
  Map<String, dynamic> json,
) => MaintenanceScheduleResponse(
  id: json['id'] as String,
  bikeId: json['bikeId'] as String,
  maintenanceType: json['maintenanceType'] as String,
  intervalKm: (json['intervalKm'] as num?)?.toInt(),
  intervalMonths: (json['intervalMonths'] as num?)?.toInt(),
  lastMaintenanceMileage: (json['lastMaintenanceMileage'] as num?)?.toInt(),
  lastMaintenanceDate: json['lastMaintenanceDate'] as String?,
  overdue: json['overdue'] as bool,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$MaintenanceScheduleResponseToJson(
  MaintenanceScheduleResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'bikeId': instance.bikeId,
  'maintenanceType': instance.maintenanceType,
  'intervalKm': instance.intervalKm,
  'intervalMonths': instance.intervalMonths,
  'lastMaintenanceMileage': instance.lastMaintenanceMileage,
  'lastMaintenanceDate': instance.lastMaintenanceDate,
  'overdue': instance.overdue,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
