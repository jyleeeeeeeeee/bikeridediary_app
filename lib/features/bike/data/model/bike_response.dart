import 'package:json_annotation/json_annotation.dart';

import '../../../../core/sync/sync_types.dart';

part 'bike_response.g.dart';

/// 서버 응답 + 로컬 저장소 통합 모델.
///
/// 서버 응답 파싱 시엔 sync 필드가 null이고, 로컬 SQLite에서 로드하면 채워진다.
/// UI는 syncState로 배지를 표시할 수 있다.
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

  /// 로컬 저장소 sync 상태. 서버 응답 파싱 시 null.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final SyncState? syncState;

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
    this.syncState,
  });

  factory BikeResponse.fromJson(Map<String, dynamic> json) =>
      _$BikeResponseFromJson(json);

  String get displayName => '$manufacturerName $modelName ($year)';

  BikeResponse copyWith({
    String? id,
    String? manufacturerName,
    String? modelName,
    int? year,
    String? category,
    int? totalMileageKm,
    bool? isRepresentative,
    String? purchasedAt,
    String? photoUrl,
    String? memo,
    double? latestFuelEfficiency,
    double? averageFuelEfficiency,
    String? createdAt,
    SyncState? syncState,
  }) {
    return BikeResponse(
      id: id ?? this.id,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      modelName: modelName ?? this.modelName,
      year: year ?? this.year,
      category: category ?? this.category,
      totalMileageKm: totalMileageKm ?? this.totalMileageKm,
      isRepresentative: isRepresentative ?? this.isRepresentative,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      memo: memo ?? this.memo,
      latestFuelEfficiency: latestFuelEfficiency ?? this.latestFuelEfficiency,
      averageFuelEfficiency: averageFuelEfficiency ?? this.averageFuelEfficiency,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
    );
  }
}
