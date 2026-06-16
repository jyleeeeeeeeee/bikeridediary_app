import 'package:json_annotation/json_annotation.dart';

part 'fueling_stats_response.g.dart';

@JsonSerializable()
class FuelingStatsResponse {
  final int totalCount;
  final double totalFuelAmount;
  final int totalCost;
  final double? averageFuelEfficiency;
  final double? latestFuelEfficiency;
  final int? averagePricePerLiter;

  FuelingStatsResponse({
    required this.totalCount,
    required this.totalFuelAmount,
    required this.totalCost,
    this.averageFuelEfficiency,
    this.latestFuelEfficiency,
    this.averagePricePerLiter,
  });

  factory FuelingStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$FuelingStatsResponseFromJson(json);
}
