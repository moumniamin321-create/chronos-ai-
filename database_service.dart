import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/goal_model.dart';

/// Chronos AI stores everything locally on the device — there is no
/// Firebase, no server, and no account system. This keeps the app free,
/// private, and fully usable offline, which matches a single-user,
/// no-budget setup.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            goals TEXT NOT NULL,
            wakeTime TEXT NOT NULL,
            sleepTime TEXT NOT NULL,
            xp INTEGER NOT NULL,
            level INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            category INTEGER NOT NULL,
            priority INTEGER NOT NULL,
            isCompleted INTEGER NOT NULL,
            isAiGenerated INTEGER NOT NULL,
            postponedCount INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE habits (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            icon TEXT NOT NULL,
            completedDates TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            deadline TEXT,
            progress REAL NOT NULL,
            isAchieved INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE memory_notes (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------- User ----------
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('user', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser() async {
    final db = await database;
    final rows = await db.query('user', limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  // ---------- Tasks ----------
  Future<void> upsertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TaskModel>> getTasksBetween(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map((r) => TaskModel.fromMap(r)).toList();
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final rows = await db.query('tasks');
    return rows.map((r) => TaskModel.fromMap(r)).toList();
  }

  // ---------- Habits ----------
  Future<void> upsertHabit(HabitModel habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitModel>> getAllHabits() async {
    final db = await database;
    final rows = await db.query('habits');
    return rows.map((r) => HabitModel.fromMap(r)).toList();
  }

  // ---------- Goals ----------
  Future<void> upsertGoal(GoalModel goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GoalModel>> getAllGoals() async {
    final db = await database;
    final rows = await db.query('goals');
    return rows.map((r) => GoalModel.fromMap(r)).toList();
  }

  // ---------- Memory notes (Atlas's long-term observations) ----------
  Future<void> addMemoryNote(String id, String content) async {
    final db = await database;
    await db.insert('memory_notes', {
      'id': id,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getMemoryNotes({int limit = 50}) async {
    final db = await database;
    final rows = await db.query('memory_notes', orderBy: 'createdAt DESC', limit: limit);
    return rows.map((r) => r['content'] as String).toList();
  }
}
