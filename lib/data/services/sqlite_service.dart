import 'dart:async';
import 'dart:io';

import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/dao/fixed_movement_dao.dart';
import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/dao/saves_dao.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:path/path.dart' as p;

part 'sqlite_service.g.dart';

@Database(version: 4, entities: [Month, MovementValue, FixedMovement, Saves])
abstract class AppDatabase extends FloorDatabase {
  MonthDao get monthDao;
  MovementValueDao get movementValueDao;
  FixedMovementDao get fixedMovementDao;
  SavesDao get savesDao;

  static Migration migration3to4 = Migration(3, 4, (database) async {
    // Create Saves table
    await database.execute(
      'CREATE TABLE IF NOT EXISTS Saves ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'monthId INTEGER NOT NULL, '
      'amount REAL NOT NULL, '
      'isInitialValue INTEGER NOT NULL CHECK (isInitialValue IN (0, 1)), '
      'date TEXT NOT NULL'
      ')',
    );
  });
}

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  late AppDatabase database;
  bool isInitialized = false;

  AppDatabase get db => database;

  // Private constructor
  SqliteService._internal();

  // Factory constructor
  factory SqliteService() {
    return _instance;
  }

  Future<String> getDatabasePath() async {
    // Usar getDatabasesPath() de sqflite
    final dbPath = await sqflite.getDatabasesPath();
    return p.join(dbPath, 'cashly_database.db');
  }

  Future<void> initializeDatabase({bool forceRecreate = false}) async {
    if (isInitialized) return;

    try {
      // Usar getDatabasesPath() de sqflite
      final path = await getDatabasePath();

      // Asegurarse de que el directorio existe
      final directory = Directory(p.dirname(path));
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      print('Inicializando base de datos en: $path');
      // Borrar la base de datos si se solicita recreación
      if (forceRecreate && File(path).existsSync()) {
        await File(path).delete();
        print('Base de datos eliminada para recreación');
      }

      final callback = Callback(
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE IF NOT EXISTS Month (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              month INTEGER NOT NULL,
              year INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE IF NOT EXISTS MovementValue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              monthId INTEGER NOT NULL,
              description TEXT NOT NULL,
              amount REAL NOT NULL,
              isExpense INTEGER NOT NULL,
              day INTEGER NOT NULL,
              category TEXT,
              FOREIGN KEY (monthId) REFERENCES Month (id) ON DELETE CASCADE
            )
          ''');

          await database.execute('''
            CREATE TABLE IF NOT EXISTS FixedMovement (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              description TEXT NOT NULL,
              amount REAL NOT NULL,
              isExpense INTEGER NOT NULL,
              day INTEGER NOT NULL,
              category TEXT NOT NULL
            )
          ''');
        },
      );

      database =
          await $FloorAppDatabase
              .databaseBuilder(path)
              .addCallback(callback)
              .addMigrations([AppDatabase.migration3to4])
              .build();

      isInitialized = true;
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }
}
