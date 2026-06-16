// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BikeUpdateRequest _$BikeUpdateRequestFromJson(Map<String, dynamic> json) =>
    BikeUpdateRequest(
      manufacturerName: json['manufacturerName'] as String,
      modelName: json['modelName'] as String,
      year: (json['year'] as num).toInt(),
      category: json['category'] as String,
      totalMileageKm: (json['totalMileageKm'] as num).toInt(),
      purchasedAt: json['purchasedAt'] as String?,
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$BikeUpdateRequestToJson(BikeUpdateRequest instance) =>
    <String, dynamic>{
      'manufacturerName': instance.manufacturerName,
      'modelName': instance.modelName,
      'year': instance.year,
      'category': instance.category,
      'totalMileageKm': instance.totalMileageKm,
      'purchasedAt': instance.purchasedAt,
      'memo': instance.memo,
    };
