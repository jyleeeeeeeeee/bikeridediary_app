class GpsPoint {
  final double lat;
  final double lng;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  GpsPoint({
    required this.lat,
    required this.lng,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'altitude': altitude,
    'speed': speed,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GpsPoint.fromJson(Map<String, dynamic> json) => GpsPoint(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    speed: (json['speed'] as num?)?.toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
