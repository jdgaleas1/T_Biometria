import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BiometricDBHelper {
  static final BiometricDBHelper _instance = BiometricDBHelper._internal();
  factory BiometricDBHelper() => _instance;
  BiometricDBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric_templates.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE biometric_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            modality TEXT,
            features TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertTemplate(
      String email, String modality, List<double> features) async {
    final db = await database;
    await db.insert(
      'biometric_templates',
      {
        'email': email,
        'modality': modality,
        'features': jsonEncode(features),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Inserted template for $email modality: $modality");
  }

  Future<List<double>> getTemplate(String email, String modality) async {
    final db = await database;
    final result = await db.query(
      'biometric_templates',
      where: 'email = ? AND modality = ?',
      whereArgs: [email, modality],
    );

    if (result.isNotEmpty) {
      final jsonList = jsonDecode(result.first['features'] as String);
      return (jsonList as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    } else {
      throw Exception('No template found for $email modality: $modality');
    }
  }

  Future<void> deleteTemplate(String email, String modality) async {
    final db = await database;
    await db.delete(
      'biometric_templates',
      where: 'email = ? AND modality = ?',
      whereArgs: [email, modality],
    );
    print("🗑️ Deleted template for $email modality: $modality");
  }

  Future<void> dropTable() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS biometric_templates');
    print("🗑️ Dropped entire biometric_templates table");
  }
}
