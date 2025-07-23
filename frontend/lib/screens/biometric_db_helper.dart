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
    print('📂 DB Path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de usuarios
        await db.execute('''
          CREATE TABLE usuarios (
            email TEXT PRIMARY KEY,
            nombres TEXT,
            apellidos TEXT,
            pais TEXT
          )
        ''');

        // Tabla de templates biométricos
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

  // ✅ Insertar datos completos de usuario + templates
  Future<void> insertarUsuarioCompleto({
    required String email,
    required String nombres,
    required String apellidos,
    required String pais,
    required Map<String, List<double>> templates,
  }) async {
    final db = await database;

    await db.insert(
        'usuarios',
        {
          'email': email,
          'nombres': nombres,
          'apellidos': apellidos,
          'pais': pais,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    for (var modalidad in templates.keys) {
      final valores = jsonEncode(templates[modalidad]);
      await db.insert('biometric_templates', {
        'email': email,
        'modality':
            modalidad.trim().toLowerCase(), // 👈 aseguramos formato uniforme
        'features': valores,
      });
    }

    print("✅ Usuario $email guardado con sus biometrías");
  }

  // ✅ Insertar un solo template biométrico
  Future<void> insertTemplate(
      String email, String modality, List<double> features) async {
    final db = await database;
    await db.insert(
      'biometric_templates',
      {
        'email': email,
        'modality':
            modality.trim().toLowerCase(), // 👈 aseguramos formato uniforme
        'features': jsonEncode(features),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("✅ Inserted template for $email modality: $modality");
  }

  // ✅ Obtener un solo template biométrico
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

  // ✅ Eliminar un template
  Future<void> deleteTemplate(String email, String modality) async {
    final db = await database;
    await db.delete(
      'biometric_templates',
      where: 'email = ? AND modality = ?',
      whereArgs: [email, modality],
    );
    print("🗑️ Deleted template for $email modality: $modality");
  }

  // ✅ Verificar si un usuario existe
  Future<bool> existeUsuario(String email) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ✅ Obtener perfil completo de usuario
  Future<Map<String, dynamic>> obtenerPerfil(String email) async {
    final db = await database;

    final usuario =
        await db.query('usuarios', where: 'email = ?', whereArgs: [email]);

    final templates = await db
        .query('biometric_templates', where: 'email = ?', whereArgs: [email]);

    if (usuario.isEmpty) {
      throw Exception("❌ Usuario no encontrado en BD: $email");
    }

    return {
      'email': email,
      'nombres': usuario.first['nombres'],
      'apellidos': usuario.first['apellidos'],
      'pais': usuario.first['pais'],
      'modalidades': templates
          .map((e) => (e['modality'] as String).trim().toLowerCase())
          .toSet()
          .toList(), // 🔁 elimina duplicados si existen
    };
  }

  Future<void> dropTables() async {
    final db = await database;
    await db.close(); // 🔁 cerrar primero
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric_templates.db');
    await deleteDatabase(path); // 🗑️ elimina el archivo real
    print("🗑️ Base de datos eliminada completamente");
    _db = null; // importante para forzar reinit
  }
}
