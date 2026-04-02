import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/run_record.dart';

class RunHistoryRepository {
  static const _dbName = 'draw_running.db';
  static const _tableName = 'run_records';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inputText TEXT NOT NULL,
            date TEXT NOT NULL,
            totalDistanceMeters REAL NOT NULL,
            durationSeconds INTEGER NOT NULL,
            paceSecondsPerKm REAL NOT NULL,
            routePolyline TEXT NOT NULL,
            segmentsJson TEXT NOT NULL,
            startLatitude REAL NOT NULL,
            startLongitude REAL NOT NULL,
            endLatitude REAL NOT NULL,
            endLongitude REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertRun(RunRecord record) async {
    final db = await database;
    return db.insert(_tableName, record.toMap());
  }

  Future<List<RunRecord>> getAllRuns() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    return maps.map(RunRecord.fromMap).toList();
  }

  Future<RunRecord?> getRun(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RunRecord.fromMap(maps.first);
  }

  Future<int> deleteRun(int id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllRuns() async {
    final db = await database;
    return db.delete(_tableName);
  }
}
