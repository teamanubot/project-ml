import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  static const _dbName = 'spineAnalyzerDB.db';
  static const _dbVersion = 2;

  // Table names
  static const usersTable = 'users';
  static const analysesTable = 'analyses';
  static const adminTable = 'admin_settings';

  // User columns
  static const userId = 'id';
  static const userName = 'name';
  static const userEmail = 'email';
  static const userPassword = 'password';
  static const userCreatedAt = 'created_at';

  // Analysis columns
  static const analysisId = 'id';
  static const analysisUserId = 'user_id';
  static const analysisImagePath = 'image_path';
  static const analysisAngle = 'angle';
  static const analysisDate = 'analysis_date';
  static const analysisNotes = 'notes';

  // Admin columns
  static const adminId = 'id';
  static const adminSettingName = 'setting_name';
  static const adminSettingValue = 'setting_value';
  static const adminUpdatedAt = 'updated_at';

  // Admin setting names
  static const adminPasswordSetting = 'admin_password';
  static const adminLastLogin = 'admin_last_login';
  static const adminLoginAttempts = 'admin_login_attempts';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $usersTable (
        $userId INTEGER PRIMARY KEY AUTOINCREMENT,
        $userName TEXT NOT NULL,
        $userEmail TEXT NOT NULL UNIQUE,
        $userPassword TEXT NOT NULL,
        $userCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE $analysesTable (
        $analysisId INTEGER PRIMARY KEY AUTOINCREMENT,
        $analysisUserId INTEGER NOT NULL,
        $analysisImagePath TEXT,
        $analysisAngle REAL,
        $analysisDate DATETIME DEFAULT CURRENT_TIMESTAMP,
        $analysisNotes TEXT,
        FOREIGN KEY($analysisUserId) REFERENCES $usersTable($userId)
      )
    ''');
    await db.execute('''
      CREATE TABLE $adminTable (
        $adminId INTEGER PRIMARY KEY AUTOINCREMENT,
        $adminSettingName TEXT NOT NULL UNIQUE,
        $adminSettingValue TEXT NOT NULL,
        $adminUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await _initializeAdminSettings(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $adminTable (
          $adminId INTEGER PRIMARY KEY AUTOINCREMENT,
          $adminSettingName TEXT NOT NULL UNIQUE,
          $adminSettingValue TEXT NOT NULL,
          $adminUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await _initializeAdminSettings(db);
    }
  }

  Future _initializeAdminSettings(Database db) async {
    await db.insert(adminTable, {
      adminSettingName: adminPasswordSetting,
      adminSettingValue: _hashPassword('admin123'),
      adminUpdatedAt: _currentTimeWIB(),
    });
  }

  // User registration, login, and profile
  Future<int> registerUser(String name, String email, String password) async {
    final dbClient = await db;
    return await dbClient.insert(usersTable, {
      userName: name,
      userEmail: email,
      userPassword: _hashPassword(password),
    });
  }

  Future<bool> loginUser(String email, String password) async {
    final dbClient = await db;
    final result = await dbClient.query(
      usersTable,
      where: '$userEmail = ? AND $userPassword = ?',
      whereArgs: [email, _hashPassword(password)],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final dbClient = await db;
    final result = await dbClient.query(
      usersTable,
      where: '$userEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> isEmailExists(String email) async {
    final dbClient = await db;
    final result = await dbClient.query(
      usersTable,
      where: '$userEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Analysis operations
  Future<int> saveAnalysis(int userId, String imagePath, double angle, String notes) async {
    final dbClient = await db;
    return await dbClient.insert(analysesTable, {
      analysisUserId: userId,
      analysisImagePath: imagePath,
      analysisAngle: angle,
      analysisNotes: notes,
      analysisDate: _currentTimeWIB(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserAnalyses(int userId) async {
    final dbClient = await db;
    return await dbClient.query(
      analysesTable,
      where: '$analysisUserId = ?',
      whereArgs: [userId],
      orderBy: '$analysisDate DESC',
    );
  }

  // Admin password and settings
  Future<String> getAdminPassword() async {
    final dbClient = await db;
    final result = await dbClient.query(
      adminTable,
      where: '$adminSettingName = ?',
      whereArgs: [adminPasswordSetting],
    );
    if (result.isNotEmpty) {
      return result.first[adminSettingValue] as String;
    } else {
      final defaultHash = _hashPassword('admin123');
      await dbClient.insert(adminTable, {
        adminSettingName: adminPasswordSetting,
        adminSettingValue: defaultHash,
        adminUpdatedAt: _currentTimeWIB(),
      });
      return defaultHash;
    }
  }

  Future<bool> verifyAdminPassword(String inputPassword) async {
    final hashedInput = _hashPassword(inputPassword.trim());
    final storedPassword = await getAdminPassword();
    return hashedInput == storedPassword;
  }

  // Utility
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _currentTimeWIB() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return now.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
  }
}