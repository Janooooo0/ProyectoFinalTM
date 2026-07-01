import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes_database.db');
    return await openDatabase(
      path,
      version: 2, // Subimos la versión para incluir el cambio de columna
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        title TEXT,
        content TEXT,
        date TEXT,
        isPinned INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    Database db = await database;
    return await db.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    Database db = await database;
    // Ordenamos primero por anclado (isPinned DESC) y luego por ID (más reciente)
    return await db.query('notes', 
        where: 'userId = ?', 
        whereArgs: [userId], 
        orderBy: 'isPinned DESC, id DESC');
  }

  Future<int> deleteNote(int id) async {
    Database db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    Database db = await database;
    return await db.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> togglePin(int id, bool currentStatus) async {
    Database db = await database;
    return await db.update('notes', {'isPinned': currentStatus ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
  }
}
