import 'package:json_annotation/json_annotation.dart';

part 'bike_response.g.dart';

@JsonSerializable()
class BikeResponse {
  final String id;
  final String manufacturerName;
  final String modelName;
  final int year;
  final String category;
  final int totalMileageKm;
  final bool isRepresentative;
  final String? purchasedAt;
  final String? photoUrl;
  final String? memo;
  final double? latestFuelEfficiency;
  final double? averageFuelEfficiency;
  final String createdAt;

  BikeResponse({
    required this.id,
    required this.manufacturerName,
    required this.modelName,
    required this.year,
    required this.category,
    required this.totalMileageKm,
    required this.isRepresentative,
    this.purchasedAt,
    this.photoUrl,
    this.memo,
    this.latestFuelEfficiency,
    this.averageFuelEfficiency,
    required this.createdAt,
  });

  factory BikeResponse.fromJson(Map<String, dynamic> json) =>
      _$BikeResponseFromJson(json);

  String get displayName => '$manufacturerName $modelName ($year)';
}
