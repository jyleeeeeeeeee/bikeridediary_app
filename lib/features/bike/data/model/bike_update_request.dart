import 'package:json_annotation/json_annotation.dart';

part 'bike_update_request.g.dart';

@JsonSerializable()
class BikeUpdateRequest {
  final String manufacturerName;
  final String modelName;
  final int year;
  final String category;
  final int totalMileageKm;
  final String? purchasedAt;
  final String? memo;

  BikeUpdateRequest({
    required this.manufacturerName,
    required this.modelName,
    required this.year,
    required this.category,
    required this.totalMileageKm,
    this.purchasedAt,
    this.memo,
  });

  Map<String, dynamic> toJson() => _$BikeUpdateRequestToJson(this);
}
