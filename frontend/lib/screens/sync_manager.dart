import 'dart:convert';
import 'package:http/http.dart' as http;
import 'biometric_db_helper.dart';

class SyncManager {
  Future<void> iniciar() async {
    print("🟢 Iniciando sincronización...");

    await _sincronizarValidaciones();
    await _sincronizarFrasesUsadas();
    await _descargarDatosNuevos();

    print("🟡 Proceso de sincronización completo.");
  }

  /// C.1 Enviar validaciones pendientes
  Future<void> _sincronizarValidaciones() async {
    final pendientes =
        await BiometricDBHelper().obtenerValidacionesPendientes();
    if (pendientes.isEmpty) {
      print("✅ No hay validaciones pendientes.");
      return;
    }

    for (final v in pendientes) {
      final exito = await _enviarValidacionAlBackend(v);
      if (exito) {
        await BiometricDBHelper()
            .marcarValidacionSincronizada(v['id_validacion']);
        print("✅ Validación ${v['id_validacion']} sincronizada.");
      } else {
        print("⚠️ Error al sincronizar validación ${v['id_validacion']}.");
      }
    }
  }

  Future<bool> _enviarValidacionAlBackend(
      Map<String, dynamic> validacion) async {
    const String url = 'http://<IP>:<PUERTO>/validaciones/sync';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "id_usuario": validacion['id_usuario'],
              "tipo_biometria": validacion['tipo_biometria'],
              "resultado": validacion['resultado'],
              "modo_validacion": validacion['modo_validacion'],
              "timestamp": validacion['timestamp'],
              "ubicacion_gps": validacion['ubicacion_gps'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return true;

      if (response.statusCode == 503 || response.statusCode == 504) {
        await BiometricDBHelper().registrarErrorSync(
          tipo: 'sync_fallida_backend',
          codigo: response.statusCode,
          mensaje: 'Backend fuera de servicio al enviar validación',
        );
      }

      return false;
    } catch (e) {
      await BiometricDBHelper().registrarErrorSync(
        tipo: 'sync_incompleta',
        codigo: 408,
        mensaje: 'Timeout o fallo de red al enviar validación: $e',
      );
      return false;
    }
  }

  /// C.1 Frases usadas o expiradas
  Future<void> _sincronizarFrasesUsadas() async {
    final frases = await BiometricDBHelper().obtenerFrasesUsadas();
    if (frases.isEmpty) return;

    for (final f in frases) {
      final exito = await _enviarFraseAlBackend(f);
      if (exito) {
        print("✅ Frase ${f['id_texto']} sincronizada.");
      } else {
        print("⚠️ Error al sincronizar frase ${f['id_texto']}.");
      }
    }
  }

  Future<bool> _enviarFraseAlBackend(Map<String, dynamic> frase) async {
    const String url = 'http://<IP>:<PUERTO>/frases/sync';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "id_usuario": frase['id_usuario'],
              "frase": frase['frase'],
              "estado_texto": frase['estado_texto'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return true;

      if (response.statusCode == 503 || response.statusCode == 504) {
        await BiometricDBHelper().registrarErrorSync(
          tipo: 'sync_fallida_backend',
          codigo: response.statusCode,
          mensaje: 'Backend fuera de servicio al enviar frase',
        );
      }

      return false;
    } catch (e) {
      await BiometricDBHelper().registrarErrorSync(
        tipo: 'sync_incompleta',
        codigo: 408,
        mensaje: 'Timeout o red fallida al enviar frase: $e',
      );
      return false;
    }
  }

  /// C.2 Descarga de datos
  Future<void> _descargarDatosNuevos() async {
    await _descargarUsuarios();
    await _descargarTemplates();
    await _descargarFrases();
  }

  Future<void> _descargarUsuarios() async {
    const String url = 'http://<IP>:<PUERTO>/usuarios/nuevos';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final List<dynamic> usuarios = jsonDecode(res.body);
      for (final u in usuarios) {
        if (!u.containsKey('identificador_unico')) {
          await BiometricDBHelper().registrarErrorSync(
            tipo: 'sync_error_integridad',
            codigo: 0,
            mensaje: 'Usuario sin campo identificador_unico',
          );
          continue;
        }

        await BiometricDBHelper().insertarUsuario(
          nombres: u['nombres'],
          apellidos: u['apellidos'],
          identificadorUnico: u['identificador_unico'],
          estado: u['estado'] ?? 'activo',
        );

        print("👤 Usuario sincronizado: ${u['identificador_unico']}");
      }
    } catch (e) {
      await BiometricDBHelper().registrarErrorSync(
        tipo: 'sync_incompleta',
        codigo: 408,
        mensaje: 'Error al descargar usuarios: $e',
      );
    }
  }

  Future<void> _descargarTemplates() async {
    const String url = 'http://<IP>:<PUERTO>/templates/nuevos';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final List<dynamic> templates = jsonDecode(res.body);
      for (final t in templates) {
        if (!t.containsKey('template') || !t.containsKey('id_usuario')) {
          await BiometricDBHelper().registrarErrorSync(
            tipo: 'sync_error_integridad',
            codigo: 0,
            mensaje: 'Template incompleto recibido',
          );
          continue;
        }

        final List<double> features = List<double>.from(t['template']);

        await BiometricDBHelper().insertarCredencialBiometrica(
          idUsuario: t['id_usuario'],
          tipoBiometria: t['tipo_biometria'],
          features: features,
          versionAlgoritmo: t['version_algoritmo'],
          validezHasta: t['validez_hasta'],
        );

        print("🧬 Template sincronizado para usuario ${t['id_usuario']}");
      }
    } catch (e) {
      await BiometricDBHelper().registrarErrorSync(
        tipo: 'sync_incompleta',
        codigo: 408,
        mensaje: 'Error al descargar templates: $e',
      );
    }
  }

  Future<void> _descargarFrases() async {
    const String url = 'http://<IP>:<PUERTO>/frases/vigentes';

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final List<dynamic> frases = jsonDecode(res.body);
      for (final f in frases) {
        if (!f.containsKey('frase') || !f.containsKey('id_usuario')) {
          await BiometricDBHelper().registrarErrorSync(
            tipo: 'sync_error_integridad',
            codigo: 0,
            mensaje: 'Frase inválida recibida',
          );
          continue;
        }

        await BiometricDBHelper().insertarTextoDinamico(
          idUsuario: f['id_usuario'],
          frase: f['frase'],
          estadoTexto: f['estado_texto'],
        );

        print("💬 Frase sincronizada para usuario ${f['id_usuario']}");
      }
    } catch (e) {
      await BiometricDBHelper().registrarErrorSync(
        tipo: 'sync_incompleta',
        codigo: 408,
        mensaje: 'Error al descargar frases: $e',
      );
    }
  }
}
