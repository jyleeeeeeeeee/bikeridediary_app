import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 가속도계 → 저역통과 필터 → 중력 벡터 추출 → 롤(뱅킹) 각도 계산.
/// 캘리브레이션 시 현재 롤을 0으로 잡아 오프셋으로 저장.
class BankingState {
  /// 캘리브레이션 보정된 현재 뱅킹각 (degree, 좌측 -, 우측 +)
  final double angle;

  /// 캘리브레이션 완료 여부 (false면 첫 calibrate() 호출 필요)
  final bool calibrated;

  /// 세션 진행 중 누적된 좌측 최대각 (음수)
  final double maxLeft;

  /// 세션 진행 중 누적된 우측 최대각 (양수)
  final double maxRight;

  const BankingState({
    required this.angle,
    required this.calibrated,
    required this.maxLeft,
    required this.maxRight,
  });

  factory BankingState.initial() => const BankingState(
        angle: 0,
        calibrated: false,
        maxLeft: 0,
        maxRight: 0,
      );

  BankingState copyWith({
    double? angle,
    bool? calibrated,
    double? maxLeft,
    double? maxRight,
  }) {
    return BankingState(
      angle: angle ?? this.angle,
      calibrated: calibrated ?? this.calibrated,
      maxLeft: maxLeft ?? this.maxLeft,
      maxRight: maxRight ?? this.maxRight,
    );
  }
}

class BankingNotifier extends Notifier<BankingState> {
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // 저역통과 필터 상태 (중력 추정용)
  double _gx = 0, _gy = 0, _gz = 0;
  bool _gravityInit = false;

  // 캘리브레이션 시점의 롤 raw 값
  double _calibrationOffset = 0;

  // 필터 강도 — 작을수록 부드러움, 클수록 반응 빠름
  // 가속도계 50Hz 기준: alpha 0.1 ≈ cutoff 약 5Hz
  static const double _alpha = 0.1;

  /// 세션 녹화 중 외부에서 등록하는 샘플 콜백 (샘플마다 호출)
  void Function(double angle, DateTime t)? _sampleSink;

  @override
  BankingState build() {
    _startSensorStream();
    ref.onDispose(() {
      _accelSub?.cancel();
    });
    return BankingState.initial();
  }

  void _startSensorStream() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // 50Hz 목표
    ).listen(_onAccel);
  }

  void _onAccel(AccelerometerEvent e) {
    if (!_gravityInit) {
      _gx = e.x;
      _gy = e.y;
      _gz = e.z;
      _gravityInit = true;
    } else {
      _gx = _gx + _alpha * (e.x - _gx);
      _gy = _gy + _alpha * (e.y - _gy);
      _gz = _gz + _alpha * (e.z - _gz);
    }

    // 휴대폰을 포트레이트(세로)로 거치한다고 가정.
    // 롤(뱅킹)은 x축 성분과 vertical 성분 사이 각도.
    // vertical은 y,z 합성 magnitude — 피치 변화에도 결과가 흔들리지 않게.
    // 부호: 음수 = 좌측 뱅킹, 양수 = 우측 뱅킹. atan2 결과 negate.
    final vertical = math.sqrt(_gy * _gy + _gz * _gz);
    final rawRoll = -math.atan2(_gx, vertical) * 180 / math.pi;

    final corrected = rawRoll - _calibrationOffset;

    double newMaxLeft = state.maxLeft;
    double newMaxRight = state.maxRight;
    if (corrected < newMaxLeft) newMaxLeft = corrected;
    if (corrected > newMaxRight) newMaxRight = corrected;

    state = state.copyWith(
      angle: corrected,
      maxLeft: newMaxLeft,
      maxRight: newMaxRight,
    );

    _sampleSink?.call(corrected, DateTime.now());
  }

  /// 거치된 상태에서 호출 — 현재 raw roll을 0으로 설정.
  void calibrate() {
    if (!_gravityInit) return;
    final vertical = math.sqrt(_gy * _gy + _gz * _gz);
    _calibrationOffset = -math.atan2(_gx, vertical) * 180 / math.pi;
    state = state.copyWith(
      angle: 0,
      calibrated: true,
      maxLeft: 0,
      maxRight: 0,
    );
  }

  /// 세션 녹화용 — 매 샘플마다 호출될 콜백 등록.
  void attachSampleSink(void Function(double angle, DateTime t) sink) {
    _sampleSink = sink;
  }

  void detachSampleSink() {
    _sampleSink = null;
  }

  /// 최대각 카운터만 리셋 (캘리브레이션 오프셋은 유지)
  void resetMaxima() {
    state = state.copyWith(maxLeft: 0, maxRight: 0);
  }
}

final bankingProvider = NotifierProvider<BankingNotifier, BankingState>(
  BankingNotifier.new,
);
