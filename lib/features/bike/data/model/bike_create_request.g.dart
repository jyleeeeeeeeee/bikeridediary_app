// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BikeCreateRequest _$BikeCreateRequestFromJson(Map<String, dynamic> json) =>
    BikeCreateRequest(
      manufacturerName: json['manufacturerName'] as String,
      modelName: json['modelName'] as String,
      year: (json['year'] as num).toInt(),
      category: json['category'] as String,
      totalMileageKm: (json['totalMileageKm'] as num).toInt(),
    );

Map<String, dynamic> _$BikeCreateRequestToJson(BikeCreateRequest instance) =>
    <String, dynamic>{
      'manufacturerName': instance.manufacturerName,
      'modelName': instance.modelName,
      'year': instance.year,
      'category': instance.category,
      'totalMileageKm': instance.totalMileageKm,
    };
