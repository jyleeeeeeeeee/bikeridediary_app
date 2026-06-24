import 'gps_point.dart';

class CourseCreateRequest {
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

  CourseCreateRequest({
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
  });

  Map<String, dynamic> toJson() => {
    'bikeId': bikeId,
    'title': title,
    'memo': memo,
    'startedAt': startedAt,
    'endedAt': endedAt,
    'durationSeconds': durationSeconds,
    'distanceKm': distanceKm,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
    'points': points.map((p) => p.toJson()).toList(),
  };
}
