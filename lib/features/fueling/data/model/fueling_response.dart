import 'package:json_annotation/json_annotation.dart';

part 'fueling_response.g.dart';

@JsonSerializable()
class FuelingResponse {
  final String id;
  final String bikeId;
  final String fuelingDate;
  final int mileageAtFueling;
  final double fuelAmount;
  final int? pricePerLiter;
  final int? totalCost;
  final String fuelType;
  final bool isFullTank;
  final double? fuelEfficiency;
  final String? memo;
  final String? stationName;
  final String createdAt;
  final String? updatedAt;

  FuelingResponse({
    required this.id,
    required this.bikeId,
    required this.fuelingDate,
    required this.mileageAtFueling,
    required this.fuelAmount,
    this.pricePerLiter,
    this.totalCost,
    required this.fuelType,
    required this.isFullTank,
    this.fuelEfficiency,
    this.memo,
    this.stationName,
    required this.createdAt,
    this.updatedAt,
  });

  factory FuelingResponse.fromJson(Map<String, dynamic> json) =>
      _$FuelingResponseFromJson(json);
}
