// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_schedule_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceScheduleUpdateRequest _$MaintenanceScheduleUpdateRequestFromJson(
  Map<String, dynamic> json,
) => MaintenanceScheduleUpdateRequest(
  intervalKm: (json['intervalKm'] as num?)?.toInt(),
  intervalMonths: (json['intervalMonths'] as num?)?.toInt(),
);

Map<String, dynamic> _$MaintenanceScheduleUpdateRequestToJson(
  MaintenanceScheduleUpdateRequest instance,
) => <String, dynamic>{
  'intervalKm': instance.intervalKm,
  'intervalMonths': instance.intervalMonths,
};
