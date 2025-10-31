// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sqlite_service.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  MonthDao? _monthDaoInstance;

  MovementValueDao? _movementValueDaoInstance;

  FixedMovementDao? _fixedMovementDaoInstance;

  SavesDao? _savesDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 4,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Month` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `month` INTEGER NOT NULL, `year` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `MovementValue` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `monthId` INTEGER NOT NULL, `description` TEXT NOT NULL, `amount` REAL NOT NULL, `isExpense` INTEGER NOT NULL, `day` INTEGER NOT NULL, `category` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `FixedMovement` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `description` TEXT NOT NULL, `amount` REAL NOT NULL, `isExpense` INTEGER NOT NULL, `day` INTEGER NOT NULL, `category` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Saves` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `monthId` INTEGER NOT NULL, `amount` REAL NOT NULL, `date` TEXT NOT NULL, `isInitialValue` INTEGER NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  MonthDao get monthDao {
    return _monthDaoInstance ??= _$MonthDao(database, changeListener);
  }

  @override
  MovementValueDao get movementValueDao {
    return _movementValueDaoInstance ??=
        _$MovementValueDao(database, changeListener);
  }

  @override
  FixedMovementDao get fixedMovementDao {
    return _fixedMovementDaoInstance ??=
        _$FixedMovementDao(database, changeListener);
  }

  @override
  SavesDao get savesDao {
    return _savesDaoInstance ??= _$SavesDao(database, changeListener);
  }
}

class _$MonthDao extends MonthDao {
  _$MonthDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _monthInsertionAdapter = InsertionAdapter(
            database,
            'Month',
            (Month item) => <String, Object?>{
                  'id': item.id,
                  'month': item.month,
                  'year': item.year
                }),
        _monthUpdateAdapter = UpdateAdapter(
            database,
            'Month',
            ['id'],
            (Month item) => <String, Object?>{
                  'id': item.id,
                  'month': item.month,
                  'year': item.year
                }),
        _monthDeletionAdapter = DeletionAdapter(
            database,
            'Month',
            ['id'],
            (Month item) => <String, Object?>{
                  'id': item.id,
                  'month': item.month,
                  'year': item.year
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Month> _monthInsertionAdapter;

  final UpdateAdapter<Month> _monthUpdateAdapter;

  final DeletionAdapter<Month> _monthDeletionAdapter;

  @override
  Future<List<Month>> findAllMonths() async {
    return _queryAdapter.queryList('SELECT * FROM Month',
        mapper: (Map<String, Object?> row) => Month(
            row['month'] as int, row['year'] as int,
            id: row['id'] as int?));
  }

  @override
  Future<int?> countAllMonths() async {
    return _queryAdapter.query('SELECT count(*) FROM Month',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<List<int>> findAllMonthIds() async {
    return _queryAdapter.queryList('SELECT id FROM Month',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<Month?> findMonthById(int id) async {
    return _queryAdapter.query('SELECT * FROM Month WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Month(
            row['month'] as int, row['year'] as int,
            id: row['id'] as int?),
        arguments: [id]);
  }

  @override
  Future<Month?> findMonthByMonthAndYear(
    int month,
    int year,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Month WHERE month = ?1 AND year = ?2 LIMIT 1',
        mapper: (Map<String, Object?> row) => Month(
            row['month'] as int, row['year'] as int,
            id: row['id'] as int?),
        arguments: [month, year]);
  }

  @override
  Future<List<int>> findAllDistinctYears() async {
    return _queryAdapter.queryList(
        'SELECT DISTINCT year FROM Month ORDER BY year DESC',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> deleteAllMonths() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Month');
  }

  @override
  Future<void> insertMonth(Month month) async {
    await _monthInsertionAdapter.insert(month, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateMonth(Month month) async {
    await _monthUpdateAdapter.update(month, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteMonth(Month month) async {
    await _monthDeletionAdapter.delete(month);
  }
}

class _$MovementValueDao extends MovementValueDao {
  _$MovementValueDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _movementValueInsertionAdapter = InsertionAdapter(
            database,
            'MovementValue',
            (MovementValue item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                }),
        _movementValueUpdateAdapter = UpdateAdapter(
            database,
            'MovementValue',
            ['id'],
            (MovementValue item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                }),
        _movementValueDeletionAdapter = DeletionAdapter(
            database,
            'MovementValue',
            ['id'],
            (MovementValue item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MovementValue> _movementValueInsertionAdapter;

  final UpdateAdapter<MovementValue> _movementValueUpdateAdapter;

  final DeletionAdapter<MovementValue> _movementValueDeletionAdapter;

  @override
  Future<List<MovementValue>> findMovementValuesByMonthId(int monthId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM MovementValue WHERE monthId = ?1',
        mapper: (Map<String, Object?> row) => MovementValue(
            row['id'] as int?,
            row['monthId'] as int,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?),
        arguments: [monthId]);
  }

  @override
  Future<List<MovementValue>> findMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM MovementValue WHERE monthId = ?1 AND isExpense = ?2',
        mapper: (Map<String, Object?> row) => MovementValue(
            row['id'] as int?,
            row['monthId'] as int,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?),
        arguments: [monthId, isExpense ? 1 : 0]);
  }

  @override
  Future<double?> sumMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  ) async {
    return _queryAdapter.query(
        'SELECT COALESCE(SUM(amount), 0.0) FROM MovementValue WHERE monthId = ?1 AND isExpense = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as double,
        arguments: [monthId, isExpense ? 1 : 0]);
  }

  @override
  Future<void> deleteAllMovements() async {
    await _queryAdapter.queryNoReturn('DELETE FROM MovementValue');
  }

  @override
  Future<int?> countMovementValuesByMonth(
    int month,
    int year,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM MovementValue WHERE monthId = (SELECT id FROM Month WHERE month = ?1 AND year = ?2)',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [month, year]);
  }

  @override
  Future<void> insertMovementValue(MovementValue movementValue) async {
    await _movementValueInsertionAdapter.insert(
        movementValue, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateMovementValue(MovementValue movementValue) async {
    await _movementValueUpdateAdapter.update(
        movementValue, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteMovementValue(MovementValue movementValue) async {
    await _movementValueDeletionAdapter.delete(movementValue);
  }
}

class _$FixedMovementDao extends FixedMovementDao {
  _$FixedMovementDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _fixedMovementInsertionAdapter = InsertionAdapter(
            database,
            'FixedMovement',
            (FixedMovement item) => <String, Object?>{
                  'id': item.id,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                }),
        _fixedMovementUpdateAdapter = UpdateAdapter(
            database,
            'FixedMovement',
            ['id'],
            (FixedMovement item) => <String, Object?>{
                  'id': item.id,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                }),
        _fixedMovementDeletionAdapter = DeletionAdapter(
            database,
            'FixedMovement',
            ['id'],
            (FixedMovement item) => <String, Object?>{
                  'id': item.id,
                  'description': item.description,
                  'amount': item.amount,
                  'isExpense': item.isExpense ? 1 : 0,
                  'day': item.day,
                  'category': item.category
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FixedMovement> _fixedMovementInsertionAdapter;

  final UpdateAdapter<FixedMovement> _fixedMovementUpdateAdapter;

  final DeletionAdapter<FixedMovement> _fixedMovementDeletionAdapter;

  @override
  Future<List<FixedMovement>> findAllFixedMovements() async {
    return _queryAdapter.queryList('SELECT * FROM FixedMovement',
        mapper: (Map<String, Object?> row) => FixedMovement(
            row['id'] as int?,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?));
  }

  @override
  Future<FixedMovement?> findFixedMovementById(int id) async {
    return _queryAdapter.query('SELECT * FROM FixedMovement WHERE id = ?1',
        mapper: (Map<String, Object?> row) => FixedMovement(
            row['id'] as int?,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?),
        arguments: [id]);
  }

  @override
  Future<List<FixedMovement>> findFixedMovementsByType(bool isExpense) async {
    return _queryAdapter.queryList(
        'SELECT * FROM FixedMovement WHERE isExpense = ?1',
        mapper: (Map<String, Object?> row) => FixedMovement(
            row['id'] as int?,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?),
        arguments: [isExpense ? 1 : 0]);
  }

  @override
  Future<void> deleteAllFixedMovements() async {
    await _queryAdapter.queryNoReturn('DELETE FROM FixedMovement');
  }

  @override
  Future<void> insertFixedMovement(FixedMovement fixedMovement) async {
    await _fixedMovementInsertionAdapter.insert(
        fixedMovement, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateFixedMovement(FixedMovement fixedMovement) async {
    await _fixedMovementUpdateAdapter.update(
        fixedMovement, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteFixedMovement(FixedMovement fixedMovement) async {
    await _fixedMovementDeletionAdapter.delete(fixedMovement);
  }
}

class _$SavesDao extends SavesDao {
  _$SavesDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _savesInsertionAdapter = InsertionAdapter(
            database,
            'Saves',
            (Saves item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'amount': item.amount,
                  'date': item.dateStr,
                  'isInitialValue': item.isInitialValue ? 1 : 0
                }),
        _savesUpdateAdapter = UpdateAdapter(
            database,
            'Saves',
            ['id'],
            (Saves item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'amount': item.amount,
                  'date': item.dateStr,
                  'isInitialValue': item.isInitialValue ? 1 : 0
                }),
        _savesDeletionAdapter = DeletionAdapter(
            database,
            'Saves',
            ['id'],
            (Saves item) => <String, Object?>{
                  'id': item.id,
                  'monthId': item.monthId,
                  'amount': item.amount,
                  'date': item.dateStr,
                  'isInitialValue': item.isInitialValue ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Saves> _savesInsertionAdapter;

  final UpdateAdapter<Saves> _savesUpdateAdapter;

  final DeletionAdapter<Saves> _savesDeletionAdapter;

  @override
  Future<List<Saves>> findAllSaves() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Saves where isInitialValue = 0',
        mapper: (Map<String, Object?> row) => Saves(
            id: row['id'] as int?,
            monthId: row['monthId'] as int,
            amount: row['amount'] as double,
            isInitialValue: (row['isInitialValue'] as int) != 0,
            dateStr: row['date'] as String));
  }

  @override
  Future<List<Saves>> findAllSavesByYear(String anno) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Saves WHERE date LIKE ?1 || \"-%\"',
        mapper: (Map<String, Object?> row) => Saves(
            id: row['id'] as int?,
            monthId: row['monthId'] as int,
            amount: row['amount'] as double,
            isInitialValue: (row['isInitialValue'] as int) != 0,
            dateStr: row['date'] as String),
        arguments: [anno]);
  }

  @override
  Future<Saves?> findSavesByMonthId(int monthId) async {
    return _queryAdapter.query('SELECT * FROM Saves WHERE monthId = ?1',
        mapper: (Map<String, Object?> row) => Saves(
            id: row['id'] as int?,
            monthId: row['monthId'] as int,
            amount: row['amount'] as double,
            isInitialValue: (row['isInitialValue'] as int) != 0,
            dateStr: row['date'] as String),
        arguments: [monthId]);
  }

  @override
  Future<List<Saves>> findSavesByIsInitialValue(bool isInitialValue) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Saves WHERE isInitialValue = ?1',
        mapper: (Map<String, Object?> row) => Saves(
            id: row['id'] as int?,
            monthId: row['monthId'] as int,
            amount: row['amount'] as double,
            isInitialValue: (row['isInitialValue'] as int) != 0,
            dateStr: row['date'] as String),
        arguments: [isInitialValue ? 1 : 0]);
  }

  @override
  Future<int?> countNonInitialSaves() async {
    return _queryAdapter.query(
        'Select count(*) from saves where isInitialValue = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<double?> sumNonInitialSaves() async {
    return _queryAdapter.query(
        'SELECT SUM(amount) FROM Saves WHERE isInitialValue = 0',
        mapper: (Map<String, Object?> row) => row.values.first as double);
  }

  @override
  Future<void> deleteAllNonInitialSaves() async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Saves where isInitialValue = 0');
  }

  @override
  Future<void> deleteSavesByMonthId(int monthId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM Saves WHERE monthId = ?1',
        arguments: [monthId]);
  }

  @override
  Future<void> insertSaves(Saves saves) async {
    await _savesInsertionAdapter.insert(saves, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateSaves(Saves saves) async {
    await _savesUpdateAdapter.update(saves, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteSaves(Saves saves) async {
    await _savesDeletionAdapter.delete(saves);
  }
}
