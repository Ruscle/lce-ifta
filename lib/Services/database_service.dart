import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ifta_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fuel_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            unit TEXT,
            fuelType TEXT,
            gallons REAL,
            state TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE trip_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            unit TEXT,
            state TEXT,
            odometerStart REAL,
            odometerEnd REAL,
            totalMiles REAL
          )
        ''');
      },
    );
  }

  static Future<int> insertFuelEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('fuel_entries', entry);
  }

  static Future<List<Map<String, dynamic>>> getFuelEntries() async {
    final db = await database;
    return await db.query('fuel_entries', orderBy: 'id DESC');
  }

  static Future<int> insertTripEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('trip_entries', entry);
  }

  static Future<List<Map<String, dynamic>>> getTripEntries() async {
    final db = await database;
    return await db.query('trip_entries', orderBy: 'id DESC');
  }

  static Future<int> updateTripEntry(int id, Map<String, dynamic> entry) async {
    final db = await database;
    return await db.update(
      'trip_entries',
      entry,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
