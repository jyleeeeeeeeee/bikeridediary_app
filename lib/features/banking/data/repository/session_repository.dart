import '../local/banking_database.dart';
import '../model/session.dart';

class SessionRepository {
  Future<int> insertSession(Session session, List<AngleSample> samples) async {
    final db = await BankingDatabase.instance();
    return db.transaction((txn) async {
      final id = await txn.insert('sessions', session.toMap());
      final batch = txn.batch();
      for (final s in samples) {
        batch.insert('angle_samples', s.toMap(id));
      }
      await batch.commit(noResult: true);
      return id;
    });
  }

  Future<List<Session>> listSessions() async {
    final db = await BankingDatabase.instance();
    final rows = await db.query('sessions', orderBy: 'started_at DESC');
    return rows.map(Session.fromMap).toList();
  }

  Future<Session?> getSession(int id) async {
    final db = await BankingDatabase.instance();
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Session.fromMap(rows.first);
  }

  Future<List<AngleSample>> listSamples(int sessionId) async {
    final db = await BankingDatabase.instance();
    final rows = await db.query(
      'angle_samples',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 't_ms ASC',
    );
    return rows.map(AngleSample.fromMap).toList();
  }

  Future<void> deleteSession(int id) async {
    final db = await BankingDatabase.instance();
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    await db.delete('angle_samples', where: 'session_id = ?', whereArgs: [id]);
  }

  /// 서버 백업 성공 후 synced_at 갱신.
  Future<void> markSynced(int sessionId, DateTime syncedAt) async {
    final db = await BankingDatabase.instance();
    await db.update(
      'sessions',
      {'synced_at': syncedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
}
