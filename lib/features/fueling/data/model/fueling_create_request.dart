import 'package:json_annotation/json_annotation.dart';

part 'fueling_create_request.g.dart';

@JsonSerializable()
class FuelingCreateRequest {
  final String bikeId;
  final String fuelingDate;
  final int mileageAtFueling;
  final double fuelAmount;
  final int? pricePerLiter;
  final int? totalCost;
  final String fuelType;
  final String? memo;
  final String? stationName;

  FuelingCreateRequest({
    required this.bikeId,
    required this.fuelingDate,
    required this.mileageAtFueling,
    required this.fuelAmount,
    this.pricePerLiter,
    this.totalCost,
    required this.fuelType,
    this.memo,
    this.stationName,
  });

  Map<String, dynamic> toJson() => _$FuelingCreateRequestToJson(this);
}
