// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_schedule_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceScheduleCreateRequest _$MaintenanceScheduleCreateRequestFromJson(
  Map<String, dynamic> json,
) => MaintenanceScheduleCreateRequest(
  bikeId: json['bikeId'] as String,
  maintenanceType: json['maintenanceType'] as String,
  intervalKm: (json['intervalKm'] as num?)?.toInt(),
  intervalMonths: (json['intervalMonths'] as num?)?.toInt(),
);

Map<String, dynamic> _$MaintenanceScheduleCreateRequestToJson(
  MaintenanceScheduleCreateRequest instance,
) => <String, dynamic>{
  'bikeId': instance.bikeId,
  'maintenanceType': instance.maintenanceType,
  'intervalKm': instance.intervalKm,
  'intervalMonths': instance.intervalMonths,
};
