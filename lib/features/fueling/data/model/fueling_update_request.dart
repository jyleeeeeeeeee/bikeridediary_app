import 'package:json_annotation/json_annotation.dart';

part 'fueling_update_request.g.dart';

@JsonSerializable()
class FuelingUpdateRequest {
  final String fuelingDate;
  final int mileageAtFueling;
  final double fuelAmount;
  final int? pricePerLiter;
  final int? totalCost;
  final String fuelType;
  final bool isFullTank;
  final String? memo;
  final String? stationName;

  FuelingUpdateRequest({
    required this.fuelingDate,
    required this.mileageAtFueling,
    required this.fuelAmount,
    this.pricePerLiter,
    this.totalCost,
    required this.fuelType,
    required this.isFullTank,
    this.memo,
    this.stationName,
  });

  Map<String, dynamic> toJson() => _$FuelingUpdateRequestToJson(this);
}
