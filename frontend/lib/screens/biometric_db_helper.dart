import 'dart:convert';
import 'dart:typed_data';
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
        await db.execute('''
          CREATE TABLE usuarios (
            id_usuario INTEGER PRIMARY KEY,
            nombres TEXT,
            apellidos TEXT,
            identificador_unico TEXT UNIQUE,
            estado TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE credenciales_biometricas (
            id_credencial INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER,
            tipo_biometria TEXT,
            template BLOB,
            validez_hasta TEXT,
            version_algoritmo TEXT,
            FOREIGN KEY(id_usuario) REFERENCES usuarios(id_usuario)
          )
        ''');

        await db.execute('''
          CREATE TABLE textos_dinamicos_audio (
            id_texto INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER,
            frase TEXT,
            estado_texto TEXT,
            FOREIGN KEY(id_usuario) REFERENCES usuarios(id_usuario)
          )
        ''');

        await db.execute('''
          CREATE TABLE validaciones_biometricas (
            id_validacion INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER,
            tipo_biometria TEXT,
            resultado TEXT,
            modo_validacion TEXT,
            timestamp TEXT,
            ubicacion_gps TEXT,
            FOREIGN KEY(id_usuario) REFERENCES usuarios(id_usuario)
          )
        ''');

        await db.execute('''
          CREATE TABLE sincronizaciones (
            id_sync INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER,
            fecha_ultima_sync TEXT,
            tipo_sync TEXT,
            estado_sync TEXT,
            cantidad_items INTEGER,
            FOREIGN KEY(id_usuario) REFERENCES usuarios(id_usuario)
          )
        ''');
      },
    );
  }

  /// ✅ Inserta un nuevo usuario
  Future<int> insertarUsuario({
    required String nombres,
    required String apellidos,
    required String identificadorUnico,
    String estado = 'activo',
  }) async {
    final db = await database;
    return await db.insert('usuarios', {
      'nombres': nombres,
      'apellidos': apellidos,
      'identificador_unico': identificadorUnico,
      'estado': estado,
    });
  }

  /// ✅ Obtener ID por identificador único
  Future<int?> obtenerIdUsuario(String identificadorUnico) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'identificador_unico = ?',
      whereArgs: [identificadorUnico],
    );
    if (res.isEmpty) return null;
    return res.first['id_usuario'] as int;
  }

  /// ✅ Obtener perfil por identificador único
  Future<Map<String, dynamic>> obtenerPerfil(String identificadorUnico) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'identificador_unico = ?',
      whereArgs: [identificadorUnico],
      limit: 1,
    );
    if (res.isEmpty) {
      throw Exception("Usuario no encontrado: $identificadorUnico");
    }
    return res.first;
  }

  /// ✅ Insertar credencial biométrica
  Future<void> insertarCredencialBiometrica({
    required int idUsuario,
    required String tipoBiometria,
    required List<double> features,
    required String versionAlgoritmo,
    String? validezHasta,
  }) async {
    final db = await database;
    final blob = Float64List.fromList(features).buffer.asUint8List();

    await db.insert('credenciales_biometricas', {
      'id_usuario': idUsuario,
      'tipo_biometria': tipoBiometria,
      'template': blob,
      'validez_hasta': validezHasta ?? '',
      'version_algoritmo': versionAlgoritmo,
    });
  }

  /// ✅ Obtener todas las credenciales de un usuario
  Future<List<Map<String, dynamic>>> obtenerCredenciales(int idUsuario) async {
    final db = await database;
    return await db.query(
      'credenciales_biometricas',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  /// ✅ Insertar frase dinámica de voz
  Future<void> insertarTextoDinamico({
    required int idUsuario,
    required String frase,
    String estadoTexto = 'activo',
  }) async {
    final db = await database;
    await db.insert('textos_dinamicos_audio', {
      'id_usuario': idUsuario,
      'frase': frase,
      'estado_texto': estadoTexto,
    });
  }

  /// ✅ Eliminar la base de datos completa (para pruebas)
  Future<void> dropTables() async {
    final db = await database;
    await db.close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'biometric_templates.db');
    await deleteDatabase(path);
    print("🗑️ Base de datos eliminada completamente");
    _db = null;
  }
}
