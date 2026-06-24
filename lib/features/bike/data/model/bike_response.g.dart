// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BikeResponse _$BikeResponseFromJson(Map<String, dynamic> json) => BikeResponse(
  id: json['id'] as String,
  manufacturerName: json['manufacturerName'] as String,
  modelName: json['modelName'] as String,
  year: (json['year'] as num).toInt(),
  category: json['category'] as String,
  totalMileageKm: (json['totalMileageKm'] as num).toInt(),
  isRepresentative: json['isRepresentative'] as bool,
  purchasedAt: json['purchasedAt'] as String?,
  photoUrl: json['photoUrl'] as String?,
  memo: json['memo'] as String?,
  latestFuelEfficiency: (json['latestFuelEfficiency'] as num?)?.toDouble(),
  averageFuelEfficiency: (json['averageFuelEfficiency'] as num?)?.toDouble(),
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$BikeResponseToJson(BikeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'manufacturerName': instance.manufacturerName,
      'modelName': instance.modelName,
      'year': instance.year,
      'category': instance.category,
      'totalMileageKm': instance.totalMileageKm,
      'isRepresentative': instance.isRepresentative,
      'purchasedAt': instance.purchasedAt,
      'photoUrl': instance.photoUrl,
      'memo': instance.memo,
      'latestFuelEfficiency': instance.latestFuelEfficiency,
      'averageFuelEfficiency': instance.averageFuelEfficiency,
      'createdAt': instance.createdAt,
    };
