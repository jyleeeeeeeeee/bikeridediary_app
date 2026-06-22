// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueling_stats_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelingStatsResponse _$FuelingStatsResponseFromJson(
  Map<String, dynamic> json,
) => FuelingStatsResponse(
  totalCount: (json['totalCount'] as num).toInt(),
  totalFuelAmount: (json['totalFuelAmount'] as num).toDouble(),
  totalCost: (json['totalCost'] as num).toInt(),
  averageFuelEfficiency: (json['averageFuelEfficiency'] as num?)?.toDouble(),
  latestFuelEfficiency: (json['latestFuelEfficiency'] as num?)?.toDouble(),
  averagePricePerLiter: (json['averagePricePerLiter'] as num?)?.toInt(),
);

Map<String, dynamic> _$FuelingStatsResponseToJson(
  FuelingStatsResponse instance,
) => <String, dynamic>{
  'totalCount': instance.totalCount,
  'totalFuelAmount': instance.totalFuelAmount,
  'totalCost': instance.totalCost,
  'averageFuelEfficiency': instance.averageFuelEfficiency,
  'latestFuelEfficiency': instance.latestFuelEfficiency,
  'averagePricePerLiter': instance.averagePricePerLiter,
};
