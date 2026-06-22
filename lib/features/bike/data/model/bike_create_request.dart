import 'package:json_annotation/json_annotation.dart';

part 'bike_create_request.g.dart';

@JsonSerializable()
class BikeCreateRequest {
  final String manufacturerName;
  final String modelName;
  final int year;
  final String category;
  final int totalMileageKm;
  final bool isExistModel;

  BikeCreateRequest({
    required this.manufacturerName,
    required this.modelName,
    required this.year,
    required this.category,
    required this.totalMileageKm,
    required this.isExistModel,
  });

  Map<String, dynamic> toJson() => _$BikeCreateRequestToJson(this);
}
