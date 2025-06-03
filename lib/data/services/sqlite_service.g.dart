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
    final path =
        name != null
            ? await sqfliteDatabaseFactory.getDatabasePath(name!)
            : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(path, _migrations, _callback);
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  MonthDao? _monthDaoInstance;

  MovementValueDao? _movementValueDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
          database,
          startVersion,
          endVersion,
          migrations,
        );

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `Month` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `month` INTEGER NOT NULL, `year` INTEGER NOT NULL)',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `MovementValue` (`id` INTEGER NOT NULL, `monthId` INTEGER NOT NULL, `description` TEXT NOT NULL, `amount` REAL NOT NULL, `isExpense` INTEGER NOT NULL, `day` INTEGER NOT NULL, `category` TEXT, PRIMARY KEY (`id`))',
        );

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
    return _movementValueDaoInstance ??= _$MovementValueDao(
      database,
      changeListener,
    );
  }
}

class _$MonthDao extends MonthDao {
  _$MonthDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _monthInsertionAdapter = InsertionAdapter(
        database,
        'Month',
        (Month item) => <String, Object?>{
          'id': item.id,
          'month': item.month,
          'year': item.year,
        },
      ),
      _monthUpdateAdapter = UpdateAdapter(
        database,
        'Month',
        ['id'],
        (Month item) => <String, Object?>{
          'id': item.id,
          'month': item.month,
          'year': item.year,
        },
      ),
      _monthDeletionAdapter = DeletionAdapter(
        database,
        'Month',
        ['id'],
        (Month item) => <String, Object?>{
          'id': item.id,
          'month': item.month,
          'year': item.year,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Month> _monthInsertionAdapter;

  final UpdateAdapter<Month> _monthUpdateAdapter;

  final DeletionAdapter<Month> _monthDeletionAdapter;

  @override
  Future<List<Month>> findAllMonths() async {
    return _queryAdapter.queryList(
      'SELECT * FROM Month',
      mapper:
          (Map<String, Object?> row) => Month(
            row['month'] as int,
            row['year'] as int,
            id: row['id'] as int?,
          ),
    );
  }

  @override
  Future<Month?> findMonthById(int id) async {
    return _queryAdapter.query(
      'SELECT * FROM Month WHERE id = ?1',
      mapper:
          (Map<String, Object?> row) => Month(
            row['month'] as int,
            row['year'] as int,
            id: row['id'] as int?,
          ),
      arguments: [id],
    );
  }

  @override
  Future<Month?> findMonthByMonthAndYear(int month, int year) async {
    return _queryAdapter.query(
      'SELECT * FROM Month WHERE month = ?1 AND year = ?2 LIMIT 1',
      mapper:
          (Map<String, Object?> row) => Month(
            row['month'] as int,
            row['year'] as int,
            id: row['id'] as int?,
          ),
      arguments: [month, year],
    );
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
  _$MovementValueDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
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
          'category': item.category,
        },
      ),
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
          'category': item.category,
        },
      ),
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
          'category': item.category,
        },
      );

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
      mapper:
          (Map<String, Object?> row) => MovementValue(
            row['id'] as int,
            row['monthId'] as int,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?,
          ),
      arguments: [monthId],
    );
  }

  @override
  Future<List<MovementValue>> findMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  ) async {
    return _queryAdapter.queryList(
      'SELECT * FROM MovementValue WHERE monthId = ?1 AND isExpense = ?2',
      mapper:
          (Map<String, Object?> row) => MovementValue(
            row['id'] as int,
            row['monthId'] as int,
            row['description'] as String,
            row['amount'] as double,
            (row['isExpense'] as int) != 0,
            row['day'] as int,
            row['category'] as String?,
          ),
      arguments: [monthId, isExpense ? 1 : 0],
    );
  }

  @override
  Future<double?> sumMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  ) async {
    return _queryAdapter.query(
      'SELECT SUM(amount) FROM MovementValue WHERE monthId = ?1 AND isExpense = ?2',
      mapper:
          (Map<String, Object?> row) =>
              row.values.first != null ? row.values.first as double : 0.0,
      arguments: [monthId, isExpense ? 1 : 0],
    );
  }

  @override
  Future<void> insertMovementValue(MovementValue movementValue) async {
    await _movementValueInsertionAdapter.insert(
      movementValue,
      OnConflictStrategy.abort,
    );
  }

  @override
  Future<void> updateMovementValue(MovementValue movementValue) async {
    await _movementValueUpdateAdapter.update(
      movementValue,
      OnConflictStrategy.abort,
    );
  }

  @override
  Future<void> deleteMovementValue(MovementValue movementValue) async {
    await _movementValueDeletionAdapter.delete(movementValue);
  }
}
