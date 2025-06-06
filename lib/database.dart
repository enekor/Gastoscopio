import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'data/models/month.dart';
import 'data/models/movement_value.dart';
import 'data/models/fixed_movement.dart';

import 'data/dao/month_dao.dart';
import 'data/dao/movement_value_dao.dart';
import 'data/dao/fixed_movement_dao.dart';

part 'database.g.dart';

@Database(version: 3, entities: [Month, MovementValue, FixedMovement])
abstract class AppDatabase extends FloorDatabase {
  MonthDao get monthDao;
  MovementValueDao get movementValueDao;
  FixedMovementDao get fixedMovementDao;
  static Migration migration1to2 = Migration(1, 2, (database) async {
    // Add unique constraint to Month table
    await database.execute(
      'CREATE TABLE IF NOT EXISTS temp_Month ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'month INTEGER NOT NULL, '
      'year INTEGER NOT NULL, '
      'UNIQUE(month, year)'
      ')',
    );
    await database.execute(
      'INSERT OR REPLACE INTO temp_Month (id, month, year) '
      'SELECT id, month, year FROM Month',
    );
    await database.execute('DROP TABLE Month');
    await database.execute('ALTER TABLE temp_Month RENAME TO Month');
  });

  static Migration migration2to3 = Migration(2, 3, (database) async {
    // Create FixedMovement table
    await database.execute(
      'CREATE TABLE IF NOT EXISTS FixedMovement ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'description TEXT NOT NULL, '
      'amount REAL NOT NULL, '
      'isExpense INTEGER NOT NULL, '
      'day INTEGER NOT NULL, '
      'category TEXT NOT NULL'
      ')',
    );
  });

  static Future<AppDatabase> initialize() async {
    return await $FloorAppDatabase
        .databaseBuilder('app_database.db')
        .addMigrations([migration1to2, migration2to3])
        .build();
  }
}
