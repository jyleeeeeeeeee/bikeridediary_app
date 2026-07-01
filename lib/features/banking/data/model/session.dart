/// 뱅킹 세션 요약 — 로컬 SQLite와 1:1 매핑.
/// 서버 백업 시에도 이 요약만 업로드하고, 상세 샘플(AngleSample)은 로컬에만 보관한다.
class Session {
  final int? id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMs;
  final double maxLeftAngle; // 음수 (좌측 최대 뱅킹)
  final double maxRightAngle; // 양수 (우측 최대 뱅킹)
  final double avgAbsAngle;
  final int sampleCount;
  final String? note;
  final DateTime? syncedAt; // 서버 백업 완료 시각 (null = 미백업)

  const Session({
    this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.maxLeftAngle,
    required this.maxRightAngle,
    required this.avgAbsAngle,
    required this.sampleCount,
    this.note,
    this.syncedAt,
  });

  bool get isSynced => syncedAt != null;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt.millisecondsSinceEpoch,
        'duration_ms': durationMs,
        'max_left_angle': maxLeftAngle,
        'max_right_angle': maxRightAngle,
        'avg_abs_angle': avgAbsAngle,
        'sample_count': sampleCount,
        'note': note,
        'synced_at': syncedAt?.millisecondsSinceEpoch,
      };

  factory Session.fromMap(Map<String, Object?> m) => Session(
        id: m['id'] as int?,
        startedAt: DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(m['ended_at'] as int),
        durationMs: m['duration_ms'] as int,
        maxLeftAngle: (m['max_left_angle'] as num).toDouble(),
        maxRightAngle: (m['max_right_angle'] as num).toDouble(),
        avgAbsAngle: (m['avg_abs_angle'] as num).toDouble(),
        sampleCount: m['sample_count'] as int,
        note: m['note'] as String?,
        syncedAt: m['synced_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['synced_at'] as int),
      );
}

class AngleSample {
  final int tMs; // 세션 시작 후 경과 ms
  final double angle;

  const AngleSample({required this.tMs, required this.angle});

  Map<String, Object?> toMap(int sessionId) => {
        'session_id': sessionId,
        't_ms': tMs,
        'angle': angle,
      };

  factory AngleSample.fromMap(Map<String, Object?> m) => AngleSample(
        tMs: m['t_ms'] as int,
        angle: (m['angle'] as num).toDouble(),
      );
}
