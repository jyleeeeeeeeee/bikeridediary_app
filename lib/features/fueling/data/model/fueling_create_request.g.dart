// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueling_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelingCreateRequest _$FuelingCreateRequestFromJson(
        Map<String, dynamic> json) =>
    FuelingCreateRequest(
      bikeId: json['bikeId'] as String,
      fuelingDate: json['fuelingDate'] as String,
      mileageAtFueling: (json['mileageAtFueling'] as num).toInt(),
      fuelAmount: (json['fuelAmount'] as num).toDouble(),
      pricePerLiter: (json['pricePerLiter'] as num?)?.toInt(),
      totalCost: (json['totalCost'] as num?)?.toInt(),
      fuelType: json['fuelType'] as String,
      isFullTank: json['isFullTank'] as bool,
      memo: json['memo'] as String?,
      stationName: json['stationName'] as String?,
    );

Map<String, dynamic> _$FuelingCreateRequestToJson(
        FuelingCreateRequest instance) =>
    <String, dynamic>{
      'bikeId': instance.bikeId,
      'fuelingDate': instance.fuelingDate,
      'mileageAtFueling': instance.mileageAtFueling,
      'fuelAmount': instance.fuelAmount,
      'pricePerLiter': instance.pricePerLiter,
      'totalCost': instance.totalCost,
      'fuelType': instance.fuelType,
      'isFullTank': instance.isFullTank,
      'memo': instance.memo,
      'stationName': instance.stationName,
    };
