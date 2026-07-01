import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 뱅킹 세션 로컬 저장소 (SQLite).
/// brd_app의 다른 도메인은 서버 DB만 쓰지만, 뱅킹 세션은 오프라인 우선이라
/// 로컬 DB를 별도 파일(brd_banking.db)로 유지한다.
class BankingDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'brd_banking.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // synced_at: 서버 백업 완료 시각 (null = 미백업)
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NOT NULL,
            duration_ms INTEGER NOT NULL,
            max_left_angle REAL NOT NULL,
            max_right_angle REAL NOT NULL,
            avg_abs_angle REAL NOT NULL,
            sample_count INTEGER NOT NULL,
            note TEXT,
            synced_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE angle_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            t_ms INTEGER NOT NULL,
            angle REAL NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_samples_session ON angle_samples(session_id)',
        );
        await db.execute(
          'CREATE INDEX idx_sessions_started ON sessions(started_at DESC)',
        );
      },
    );
    return _db!;
  }
}
