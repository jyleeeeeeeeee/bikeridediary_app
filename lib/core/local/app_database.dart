import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 로컬 우선 도메인의 통합 SQLite.
///
/// 각 도메인(바이크/정비/주유)이 자기 Phase에서 이 파일의 _onCreate/_onUpgrade에 CREATE TABLE을 추가한다.
/// 버전을 1씩 올리고 _migrations에 해당 스텝을 추가하면 기존 유저의 DB도 자동 업그레이드된다.
///
/// 뱅킹 세션은 이 통합 DB에 넣지 않는다 — 대용량 샘플 데이터라 별도 파일(brd_banking.db) 유지.
/// [BankingDatabase] 참조.
class AppDatabase {
  static Database? _db;
  static const _dbName = 'brd_local.db';
  static const _currentVersion = 2;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _db!;
  }

  /// 신규 설치 유저 — 모든 마이그레이션을 순차 실행한다.
  static Future<void> _onCreate(Database db, int version) async {
    for (int v = 1; v <= version; v++) {
      await _migrations[v]?.call(db);
    }
  }

  /// 기존 유저 — oldVersion+1 부터 newVersion까지 순차 실행.
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      await _migrations[v]?.call(db);
    }
  }

  /// 버전별 마이그레이션. 각 도메인이 자기 Phase에서 여기에 스텝을 추가한다.
  static final Map<int, Future<void> Function(Database)> _migrations = {
    1: (db) async {
      // 인프라 자체엔 테이블 없음.
    },
    2: (db) async {
      // 바이크 도메인 로컬 저장소.
      // id: 클라이언트 UUID v4. 서버는 이 UUID를 그대로 PK로 수용.
      // sync 컬럼: sync_state/updated_at/synced_at/sync_error/deleted_at (공통).
      await db.execute('''
        CREATE TABLE bikes (
          id TEXT PRIMARY KEY,
          manufacturer_name TEXT NOT NULL,
          model_name TEXT NOT NULL,
          year INTEGER NOT NULL,
          category TEXT NOT NULL,
          total_mileage_km INTEGER NOT NULL DEFAULT 0,
          is_representative INTEGER NOT NULL DEFAULT 0,
          purchased_at TEXT,
          photo_url TEXT,
          memo TEXT,
          created_at INTEGER NOT NULL,
          sync_state TEXT NOT NULL DEFAULT 'PENDING',
          updated_at INTEGER NOT NULL,
          synced_at INTEGER,
          sync_error TEXT,
          deleted_at INTEGER
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_bikes_sync_state ON bikes(sync_state)',
      );
      await db.execute(
        'CREATE INDEX idx_bikes_deleted ON bikes(deleted_at)',
      );
    },
  };

  /// 로그아웃 시 로컬 데이터 전체 삭제 (한 기기 = 한 유저 전제).
  /// 도메인이 추가될 때마다 여기에 DELETE 문 추가.
  static Future<void> clearAll() async {
    final db = await instance();
    await db.transaction((txn) async {
      await txn.delete('bikes');
    });
  }
}
