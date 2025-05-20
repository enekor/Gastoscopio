import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'data/models/month.dart';
import 'data/models/movement_value.dart';

import 'data/dao/month_dao.dart';
import 'data/dao/movement_value_dao.dart';

part 'database.g.dart'; // Este archivo se genera automáticamente

@Database(version: 1, entities: [Month, MovementValue])
abstract class AppDatabase extends FloorDatabase {
  MonthDao get monthDao;
  MovementValueDao get movementValueDao;
}
