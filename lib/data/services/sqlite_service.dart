
import 'dart:async';

import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:floor/floor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../database.dart';
import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:path/path.dart' as p;


part 'sqlite_service.g.dart';

@Database(version: 1, entities: [Month, MovementValue])
abstract class AppDatabase extends FloorDatabase {
  MonthDao get monthDao;
  MovementValueDao get movementValueDao;
}

class SqliteService {
  static late AppDatabase database;

  static Future<void> initializeDatabase() async {
    
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'cashly_database.db');

    /*
    Para crear nueva version
    
    final migration1to2 = Migration(1, 2, (database) async {
      await database.execute('ALTER TABLE Expense ADD COLUMN category TEXT');
    });

    añadir .addMigrations([migration1to2]) antes del build()
    */
    database = await $FloorAppDatabase
      .databaseBuilder(dbPath)
      .build();
  }
}

