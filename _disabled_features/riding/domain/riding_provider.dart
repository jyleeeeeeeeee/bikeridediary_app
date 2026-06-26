import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/model/gps_point.dart';

// 라이딩 상태
enum RidingStatus { idle, recording, paused }

class RidingState {
  final RidingStatus status;
  final List<GpsPoint> points;
  final DateTime? startedAt;
  final Duration elapsed;
  final double distanceKm;
  final double currentSpeedKmh;
  final double maxSpeedKmh;

  const RidingState({
    this.status = RidingStatus.idle,
    this.points = const [],
    this.startedAt,
    this.elapsed = Duration.zero,
    this.distanceKm = 0,
    this.currentSpeedKmh = 0,
    this.maxSpeedKmh = 0,
  });

  double get avgSpeedKmh {
    if (elapsed.inSeconds == 0) return 0;
    return distanceKm / (elapsed.inSeconds / 3600);
  }

  RidingState copyWith({
    RidingStatus? status,
    List<GpsPoint>? points,
    DateTime? startedAt,
    Duration? elapsed,
    double? distanceKm,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
  }) {
    return RidingState(
      status: status ?? this.status,
      points: points ?? this.points,
      startedAt: startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      distanceKm: distanceKm ?? this.distanceKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
    );
  }
}

class RidingNotifier extends StateNotifier<RidingState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;

  RidingNotifier() : super(const RidingState());

  Future<void> start() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('위치 서비스를 활성화해주세요.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 필요합니다.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('설정에서 위치 권한을 허용해주세요.');
    }

    state = RidingState(
      status: RidingStatus.recording,
      startedAt: DateTime.now(),
      points: [],
    );

    _startTimer();
    _startLocationStream();
  }

  void pause() {
    _positionSub?.pause();
    _timer?.cancel();
    state = state.copyWith(status: RidingStatus.paused);
  }

  void resume() {
    _positionSub?.resume();
    _startTimer();
    state = state.copyWith(status: RidingStatus.recording);
  }

  RidingState stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _timer?.cancel();
    _timer = null;
    final result = state;
    state = state.copyWith(status: RidingStatus.idle);
    return result;
  }

  void reset() {
    _positionSub?.cancel();
    _positionSub = null;
    _timer?.cancel();
    _timer = null;
    state = const RidingState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == RidingStatus.recording) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );
      }
    });
  }

  void _startLocationStream() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (state.status != RidingStatus.recording) return;

    final point = GpsPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      altitude: pos.altitude,
      speed: pos.speed * 3.6,
      timestamp: DateTime.now(),
    );

    double newDistance = state.distanceKm;
    if (state.points.isNotEmpty) {
      final last = state.points.last;
      newDistance += _haversineKm(last.lat, last.lng, point.lat, point.lng);
    }

    final speedKmh = pos.speed * 3.6;

    state = state.copyWith(
      points: [...state.points, point],
      distanceKm: newDistance,
      currentSpeedKmh: speedKmh < 0 ? 0 : speedKmh,
      maxSpeedKmh: speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh,
    );
  }

  // Haversine 공식으로 두 좌표 간 거리 계산 (km)
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

final ridingProvider = StateNotifierProvider<RidingNotifier, RidingState>((ref) {
  return RidingNotifier();
});
