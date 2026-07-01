/// 로컬 저장소 레코드의 서버 동기화 상태.
/// 모든 로컬 우선 도메인 테이블은 sync_state, updated_at, synced_at, sync_error, deleted_at 컬럼을 공통으로 갖는다.
enum SyncState {
  /// 로컬 변경분이 아직 서버에 반영되지 않음. sync engine이 재시도 대상으로 삼음.
  pending,

  /// 서버와 동기화 완료.
  synced,

  /// 마지막 sync 시도가 실패 — sync_error 컬럼에 사유. 유저에게 UI로 표시.
  failed,
}

extension SyncStateSql on SyncState {
  String get sql {
    switch (this) {
      case SyncState.pending:
        return 'PENDING';
      case SyncState.synced:
        return 'SYNCED';
      case SyncState.failed:
        return 'FAILED';
    }
  }

  static SyncState fromSql(String value) {
    switch (value) {
      case 'PENDING':
        return SyncState.pending;
      case 'SYNCED':
        return SyncState.synced;
      case 'FAILED':
        return SyncState.failed;
    }
    throw ArgumentError('Unknown sync_state: $value');
  }
}

/// 도메인 sync 서비스 계약. Sync engine이 등록된 서비스 목록을 순회하며 syncPending()을 호출한다.
///
/// 구현체는 다음을 수행해야 한다:
/// 1. sync_state = PENDING인 로컬 레코드 조회
/// 2. 서버 upsert API 호출 (client-side UUID는 그대로 사용)
/// 3. 성공 시 sync_state = SYNCED + synced_at 갱신, 실패 시 sync_state = FAILED + sync_error 저장
/// 4. deleted_at != null인 레코드는 서버에도 삭제 반영 후 로컬 hard delete
///
/// 절대 throw 하지 않는다 — 도메인 단위 실패는 sync_state로만 표현. sync engine은 전체 순회를 계속.
abstract class Syncable {
  /// 도메인 식별용 이름 (로깅/디버깅 목적).
  String get name;

  Future<void> syncPending();
}

/// 공통 SQLite 컬럼 정의 — 도메인별 테이블에 그대로 붙여 쓰는 스니펫.
/// 참조: bike_migrations, maintenance_migrations 등에서 사용.
const String syncColumnsSql = '''
    sync_state TEXT NOT NULL DEFAULT 'PENDING',
    updated_at INTEGER NOT NULL,
    synced_at INTEGER,
    sync_error TEXT,
    deleted_at INTEGER
''';
