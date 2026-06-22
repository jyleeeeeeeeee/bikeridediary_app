// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueling_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelingResponse _$FuelingResponseFromJson(Map<String, dynamic> json) =>
    FuelingResponse(
      id: json['id'] as String,
      bikeId: json['bikeId'] as String,
      fuelingDate: json['fuelingDate'] as String,
      mileageAtFueling: (json['mileageAtFueling'] as num).toInt(),
      fuelAmount: (json['fuelAmount'] as num).toDouble(),
      pricePerLiter: (json['pricePerLiter'] as num?)?.toInt(),
      totalCost: (json['totalCost'] as num?)?.toInt(),
      fuelType: json['fuelType'] as String,
      fuelEfficiency: (json['fuelEfficiency'] as num?)?.toDouble(),
      memo: json['memo'] as String?,
      stationName: json['stationName'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$FuelingResponseToJson(FuelingResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bikeId': instance.bikeId,
      'fuelingDate': instance.fuelingDate,
      'mileageAtFueling': instance.mileageAtFueling,
      'fuelAmount': instance.fuelAmount,
      'pricePerLiter': instance.pricePerLiter,
      'totalCost': instance.totalCost,
      'fuelType': instance.fuelType,
      'fuelEfficiency': instance.fuelEfficiency,
      'memo': instance.memo,
      'stationName': instance.stationName,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
