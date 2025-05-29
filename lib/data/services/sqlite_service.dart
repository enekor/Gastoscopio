import 'dart:async';
import 'dart:io';

import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
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

  Future<void> initializeDatabase({bool forceRecreate = false}) async {
    if (isInitialized) return;

    try {
      // Usar getDatabasesPath() de sqflite
      final dbPath = await sqflite.getDatabasesPath();
      final path = p.join(dbPath, 'cashly_database.db');

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
        },
      );

      database =
          await $FloorAppDatabase
              .databaseBuilder(path)
              .addCallback(callback)
              .build();

      isInitialized = true;
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }
}
