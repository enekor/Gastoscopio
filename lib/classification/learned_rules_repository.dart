import 'package:cashly/data/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

import 'learned_rules.dart';

/// Persistencia de lo aprendido en la base de datos de la app.
///
/// Vive en la misma base de datos que los movimientos, así que viaja con el
/// backup de Google Drive. Las tablas se crean en
/// `SqliteService.initializeDatabase`.
class LearnedRulesRepository {
  DatabaseExecutor get _db => SqliteService().db.database;

  Future<List<Map<String, Object?>>> loadAll() {
    return _db.rawQuery(
      'SELECT kind, ruleKey, value, hits, updatedAt FROM ClassificationRule',
    );
  }

  Future<void> save(
    LearnedRuleKind kind,
    String key,
    LearnedRuleValue value,
  ) {
    return _db.rawInsert(
      'INSERT OR REPLACE INTO ClassificationRule '
      '(kind, ruleKey, value, hits, updatedAt) VALUES (?, ?, ?, ?, ?)',
      [kind.dbValue, key, value.value, value.hits, value.updatedAt],
    );
  }

  Future<void> deleteKey(LearnedRuleKind kind, String key) {
    return _db.rawDelete(
      'DELETE FROM ClassificationRule WHERE kind = ? AND ruleKey = ?',
      [kind.dbValue, key],
    );
  }

  Future<void> deleteAll() => _db.rawDelete('DELETE FROM ClassificationRule');

  /// Comercio original (clave normalizada) del que salió un movimiento.
  Future<String?> findMovementMerchantKey(int movementId) async {
    final rows = await _db.rawQuery(
      'SELECT merchantKey FROM MovementMerchantKey WHERE movementId = ? LIMIT 1',
      [movementId],
    );
    if (rows.isEmpty) return null;
    return rows.first['merchantKey'] as String?;
  }

  Future<void> saveMovementMerchantKey(int movementId, String merchantKey) {
    return _db.rawInsert(
      'INSERT OR REPLACE INTO MovementMerchantKey (movementId, merchantKey) '
      'VALUES (?, ?)',
      [movementId, merchantKey],
    );
  }

  /// Borra las claves de movimientos que ya no existen.
  Future<void> deleteOrphanMerchantKeys() {
    return _db.rawDelete(
      'DELETE FROM MovementMerchantKey '
      'WHERE movementId NOT IN (SELECT id FROM MovementValue)',
    );
  }
}
