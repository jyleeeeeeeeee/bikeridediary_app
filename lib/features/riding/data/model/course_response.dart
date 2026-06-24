import 'gps_point.dart';

class CourseResponse {
  final String id;
  final String bikeId;
  final String title;
  final String? memo;
  final String startedAt;
  final String endedAt;
  final int durationSeconds;
  final double distanceKm;
  final double? avgSpeedKmh;
  final double? maxSpeedKmh;
  final List<GpsPoint> points;
  final String createdAt;

  CourseResponse({
    required this.id,
    required this.bikeId,
    required this.title,
    this.memo,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.distanceKm,
    this.avgSpeedKmh,
    this.maxSpeedKmh,
    required this.points,
    required this.createdAt,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List? ?? [];
    return CourseResponse(
      id: json['id'] as String,
      bikeId: json['bikeId'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble(),
      points: pointsList.map((e) => GpsPoint.fromJson(e)).toList(),
      createdAt: json['createdAt'] as String,
    );
  }
}
