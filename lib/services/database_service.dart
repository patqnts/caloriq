// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'caloriq.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE weight_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            morningWeight REAL NOT NULL,
            eveningWeight REAL,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE food_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            mealType INTEGER NOT NULL,
            amountGrams REAL NOT NULL,
            note TEXT,
            barcode TEXT,
            foodName TEXT,
            brand TEXT,
            caloriesPer100g REAL,
            proteinPer100g REAL,
            carbsPer100g REAL,
            fatPer100g REAL,
            imageUrl TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE exercise_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT NOT NULL,
            durationMinutes INTEGER,
            caloriesBurned INTEGER,
            source TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE food_cache (
            barcode TEXT PRIMARY KEY,
            name TEXT,
            brand TEXT,
            caloriesPer100g REAL,
            proteinPer100g REAL,
            carbsPer100g REAL,
            fatPer100g REAL,
            imageUrl TEXT,
            lastUsed INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE custom_foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT,
            caloriesPer100g REAL,
            proteinPer100g REAL,
            carbsPer100g REAL,
            fatPer100g REAL,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveWeightEntry(WeightEntry entry) async {
    final d = await db;
    await d.insert('weight_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWeightEntry(int id) async {
    final d = await db;
    await d.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WeightEntry>> getWeightEntries({int limit = 90}) async {
    final d = await db;
    final rows = await d.query('weight_entries',
        orderBy: 'date DESC', limit: limit);
    return rows.map(WeightEntry.fromMap).toList();
  }

  Future<void> saveFoodLog(FoodLog log) async {
    final d = await db;
    await d.insert('food_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await d.insert(
      'food_cache',
      {...log.food.toMap(), 'lastUsed': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFoodLog(int id) async {
    final d = await db;
    await d.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await d.query('food_logs',
        where: 'date = ?', whereArgs: [dateStr], orderBy: 'id ASC');
    return rows.map(FoodLog.fromMap).toList();
  }

  Future<void> saveExerciseLog(ExerciseLog log) async {
    final d = await db;
    await d.insert('exercise_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteExerciseLog(int id) async {
    final d = await db;
    await d.delete('exercise_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExerciseLog>> getExerciseLogsForDate(DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await d.query('exercise_logs',
        where: 'date = ?', whereArgs: [dateStr]);
    return rows.map(ExerciseLog.fromMap).toList();
  }

  Future<List<FoodItem>> getRecentFoods({int limit = 20}) async {
    final d = await db;
    final rows = await d.query('food_cache',
        orderBy: 'lastUsed DESC', limit: limit);
    return rows.map(FoodItem.fromMap).toList();
  }

  Future<Map<String, double>> getCaloriesLast7Days() async {
    final d = await db;
    final result = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final foodRows = await d.rawQuery(
        'SELECT SUM(caloriesPer100g * amountGrams / 100) as total FROM food_logs WHERE date = ?',
        [dateStr],
      );
      final exerciseRows = await d.rawQuery(
        'SELECT SUM(caloriesBurned) as total FROM exercise_logs WHERE date = ?',
        [dateStr],
      );
      final foodCals =
          (foodRows.first['total'] as num?)?.toDouble() ?? 0;
      final exerciseCals =
          (exerciseRows.first['total'] as num?)?.toDouble() ?? 0;
      result[dateStr] = foodCals - exerciseCals;
    }
    return result;
  }

  Future<void> saveCustomFood(CustomFood food) async {
    final d = await db;
    await d.insert('custom_foods', food.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCustomFood(int id) async {
    final d = await db;
    await d.delete('custom_foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCustomFood(CustomFood food) async {
    final d = await db;
    await d.update('custom_foods', food.toMap(),
        where: 'id = ?', whereArgs: [food.id]);
  }

  Future<List<CustomFood>> getCustomFoods() async {
    final d = await db;
    final rows = await d.query('custom_foods', orderBy: 'name ASC');
    return rows.map(CustomFood.fromMap).toList();
  }
}
