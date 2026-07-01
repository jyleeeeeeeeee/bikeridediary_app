import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/model/session.dart';
import '../data/repository/session_repository.dart';
import 'banking_provider.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(),
);

class RecordingState {
  final bool isRecording;
  final DateTime? startedAt;
  final int sampleCount;

  const RecordingState({
    required this.isRecording,
    required this.startedAt,
    required this.sampleCount,
  });

  factory RecordingState.idle() => const RecordingState(
        isRecording: false,
        startedAt: null,
        sampleCount: 0,
      );
}

/// 라이딩 세션 녹화 상태.
/// 녹화 시작/종료 시점에 wakelock을 함께 관리해서, 다른 화면으로 이동해도
/// 앱 내에 있는 한 화면이 꺼지지 않게 한다 (Doze mode 발동 방지).
///
/// 메모리 사용량: 50Hz × 1시간 = 18만 샘플 × 16 bytes ≈ 2.9MB.
/// 디스크 IO보다 메모리 축적 후 종료 시 일괄 저장이 훨씬 가볍다.
class RecordingNotifier extends Notifier<RecordingState> {
  final List<AngleSample> _buffer = [];

  @override
  RecordingState build() {
    return RecordingState.idle();
  }

  Future<void> start() async {
    if (state.isRecording) return;
    _buffer.clear();
    final startTime = DateTime.now();
    ref.read(bankingProvider.notifier).resetMaxima();
    ref.read(bankingProvider.notifier).attachSampleSink((angle, t) {
      final tMs = t.difference(startTime).inMilliseconds;
      _buffer.add(AngleSample(tMs: tMs, angle: angle));
      state = RecordingState(
        isRecording: true,
        startedAt: startTime,
        sampleCount: _buffer.length,
      );
    });
    state = RecordingState(
      isRecording: true,
      startedAt: startTime,
      sampleCount: 0,
    );
    // 녹화 중 자동 잠금 방지 — 뱅킹 화면을 벗어나 다른 탭으로 가도 유지.
    await WakelockPlus.enable();
  }

  /// 세션 종료 → DB 저장 → 새 세션 id 반환.
  Future<int?> stopAndSave({String? note}) async {
    if (!state.isRecording || state.startedAt == null) return null;
    final endedAt = DateTime.now();
    final startedAt = state.startedAt!;
    ref.read(bankingProvider.notifier).detachSampleSink();

    final samples = List<AngleSample>.from(_buffer);
    final banking = ref.read(bankingProvider);

    final avgAbs = samples.isEmpty
        ? 0.0
        : samples.map((s) => s.angle.abs()).reduce((a, b) => a + b) /
            samples.length;

    final session = Session(
      startedAt: startedAt,
      endedAt: endedAt,
      durationMs: endedAt.difference(startedAt).inMilliseconds,
      maxLeftAngle: banking.maxLeft,
      maxRightAngle: banking.maxRight,
      avgAbsAngle: avgAbs,
      sampleCount: samples.length,
      note: note,
    );

    final id = await ref
        .read(sessionRepositoryProvider)
        .insertSession(session, samples);

    _buffer.clear();
    state = RecordingState.idle();
    await WakelockPlus.disable();
    return id;
  }

  Future<void> cancel() async {
    if (!state.isRecording) return;
    ref.read(bankingProvider.notifier).detachSampleSink();
    _buffer.clear();
    state = RecordingState.idle();
    await WakelockPlus.disable();
  }
}

final recordingProvider = NotifierProvider<RecordingNotifier, RecordingState>(
  RecordingNotifier.new,
);

/// 저장된 세션 목록 — pull-to-refresh로 invalidate.
final sessionListProvider = FutureProvider<List<Session>>((ref) async {
  return ref.read(sessionRepositoryProvider).listSessions();
});

final sessionDetailProvider =
    FutureProvider.family<({Session? session, List<AngleSample> samples}), int>(
        (ref, id) async {
  final repo = ref.read(sessionRepositoryProvider);
  final session = await repo.getSession(id);
  final samples = await repo.listSamples(id);
  return (session: session, samples: samples);
});
