import 'package:sqflite/sqflite.dart';

import '../../../../core/local/app_database.dart';
import '../../../../core/sync/sync_types.dart';
import '../model/bike_response.dart';

/// 바이크 로컬 SQLite CRUD.
///
/// UI/Provider는 이 리포지토리만 사용. 서버 통신은 BikeSyncService를 통해서만 발생.
///
/// created_at는 최초 생성 시각으로 고정(변하지 않는다).
/// updated_at은 로컬 변경 시마다 갱신 — LWW 판별의 기준.
class BikeLocalRepository {
  BikeLocalRepository();

  Future<void> upsert(BikeResponse bike, {SyncState? state}) async {
    final db = await AppDatabase.instance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'bikes',
      {
        'id': bike.id,
        'manufacturer_name': bike.manufacturerName,
        'model_name': bike.modelName,
        'year': bike.year,
        'category': bike.category,
        'total_mileage_km': bike.totalMileageKm,
        'is_representative': bike.isRepresentative ? 1 : 0,
        'purchased_at': bike.purchasedAt,
        'photo_url': bike.photoUrl,
        'memo': bike.memo,
        'created_at':
            DateTime.tryParse(bike.createdAt)?.millisecondsSinceEpoch ?? now,
        'sync_state': (state ?? SyncState.pending).sql,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 삭제되지 않은(deleted_at IS NULL) 바이크 목록.
  Future<List<BikeResponse>> listActive() async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'bikes',
      where: 'deleted_at IS NULL',
      orderBy: 'is_representative DESC, created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<BikeResponse?> find(String id) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'bikes',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// UI 업데이트용 — 클라이언트 변경 시 sync_state=PENDING 자동.
  Future<void> updateFields(String id, Map<String, Object?> fields) async {
    final db = await AppDatabase.instance();
    await db.update(
      'bikes',
      {
        ...fields,
        'sync_state': SyncState.pending.sql,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 대표 지정: 다른 모든 바이크를 해제하고 대상만 대표로.
  /// 원자적 트랜잭션으로 처리.
  Future<void> setRepresentative(String id) async {
    final db = await AppDatabase.instance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update(
        'bikes',
        {
          'is_representative': 0,
          'sync_state': SyncState.pending.sql,
          'updated_at': now,
        },
        where: 'is_representative = 1 AND id != ?',
        whereArgs: [id],
      );
      await txn.update(
        'bikes',
        {
          'is_representative': 1,
          'sync_state': SyncState.pending.sql,
          'updated_at': now,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// soft delete — deleted_at 세팅. sync 성공 후 hard delete.
  Future<void> softDelete(String id) async {
    final db = await AppDatabase.instance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'bikes',
      {
        'deleted_at': now,
        'sync_state': SyncState.pending.sql,
        'updated_at': now,
        'sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hardDelete(String id) async {
    final db = await AppDatabase.instance();
    await db.delete('bikes', where: 'id = ?', whereArgs: [id]);
  }

  /// sync engine용 — sync_state가 PENDING 또는 FAILED인 레코드(재시도 포함).
  Future<List<Map<String, Object?>>> listPendingRaw() async {
    final db = await AppDatabase.instance();
    return db.query(
      'bikes',
      where: "sync_state IN ('PENDING', 'FAILED')",
    );
  }

  Future<void> markSynced(String id) async {
    final db = await AppDatabase.instance();
    await db.update(
      'bikes',
      {
        'sync_state': SyncState.synced.sql,
        'synced_at': DateTime.now().millisecondsSinceEpoch,
        'sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    final db = await AppDatabase.instance();
    await db.update(
      'bikes',
      {
        'sync_state': SyncState.failed.sql,
        'sync_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  BikeResponse _fromRow(Map<String, Object?> row) {
    return BikeResponse(
      id: row['id'] as String,
      manufacturerName: row['manufacturer_name'] as String,
      modelName: row['model_name'] as String,
      year: row['year'] as int,
      category: row['category'] as String,
      totalMileageKm: row['total_mileage_km'] as int,
      isRepresentative: (row['is_representative'] as int) == 1,
      purchasedAt: row['purchased_at'] as String?,
      photoUrl: row['photo_url'] as String?,
      memo: row['memo'] as String?,
      // 연비는 서버 계산값. 로컬엔 저장 안 함 → null.
      latestFuelEfficiency: null,
      averageFuelEfficiency: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int)
          .toIso8601String(),
      syncState: SyncStateSql.fromSql(row['sync_state'] as String),
    );
  }
}
