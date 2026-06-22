// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueling_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelingUpdateRequest _$FuelingUpdateRequestFromJson(
  Map<String, dynamic> json,
) => FuelingUpdateRequest(
  fuelingDate: json['fuelingDate'] as String,
  mileageAtFueling: (json['mileageAtFueling'] as num).toInt(),
  fuelAmount: (json['fuelAmount'] as num).toDouble(),
  pricePerLiter: (json['pricePerLiter'] as num?)?.toInt(),
  totalCost: (json['totalCost'] as num?)?.toInt(),
  fuelType: json['fuelType'] as String,
  memo: json['memo'] as String?,
  stationName: json['stationName'] as String?,
);

Map<String, dynamic> _$FuelingUpdateRequestToJson(
  FuelingUpdateRequest instance,
) => <String, dynamic>{
  'fuelingDate': instance.fuelingDate,
  'mileageAtFueling': instance.mileageAtFueling,
  'fuelAmount': instance.fuelAmount,
  'pricePerLiter': instance.pricePerLiter,
  'totalCost': instance.totalCost,
  'fuelType': instance.fuelType,
  'memo': instance.memo,
  'stationName': instance.stationName,
};
