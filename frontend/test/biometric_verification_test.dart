import 'package:flutter_test/flutter_test.dart';
import 'package:tesisprueba/screens/biometric_verification.dart';
import 'package:tesisprueba/screens/biometric_db_helper.dart';

void main() {
  const identificador = 'user123';
  const tipoBiometria = 'oido';

  final storedFeatures = [0.8, 0.6, 0.9];
  final currentFeaturesSuccess = [0.8, 0.6, 0.8];
  final currentFeaturesFail = [0.2, 0.3, 0.4];

  group('Pruebas unitarias - Comparación de características biométricas', () {
    test('Verificación de Oído - Comparación exitosa', () async {
      final biometricVerification = BiometricVerification(
        identificador: identificador,
        selected: ['Voz', 'Oído'],
      );

      final result = await biometricVerification.verificarOido(
        storedFeatures,
        currentFeaturesSuccess,
      );
      expect(result, true);
    });

    test('Verificación de Oído - Comparación fallida', () async {
      final biometricVerification = BiometricVerification(
        identificador: identificador,
        selected: ['Voz', 'Oído'],
      );

      final result = await biometricVerification.verificarOido(
        storedFeatures,
        currentFeaturesFail,
      );
      expect(result, false);
    });
  });

  group('Pruebas de integración - Base de datos y módulos biométricos', () {
    test('Integración: guardar y recuperar template', () async {
      final db = BiometricDBHelper();

      // Inserta usuario si no existe
      int? idUsuario = await db.obtenerIdUsuario(identificador);
      idUsuario ??= await db.insertarUsuario(
        nombres: 'Usuario',
        apellidos: 'Ejemplo',
        identificadorUnico: identificador,
      );

      // Inserta plantilla biométrica
      await db.insertarCredencialBiometrica(
        idUsuario: idUsuario,
        tipoBiometria: tipoBiometria,
        features: storedFeatures,
        versionAlgoritmo: '1.0',
      );

      final credenciales = await db.obtenerCredenciales(idUsuario);
      expect(
          credenciales.any((c) => c['tipo_biometria'] == tipoBiometria), true);
    });
  });

  group('Pruebas de validación - Falsos positivos y negativos', () {
    test('Detecta correctamente falsos positivos y negativos', () async {
      final biometricVerification = BiometricVerification(
        identificador: identificador,
        selected: ['Voz', 'Oído'],
      );

      final resultNegativo = await biometricVerification.verificarOido(
        storedFeatures,
        currentFeaturesFail,
      );
      expect(resultNegativo, false);

      final resultPositivo = await biometricVerification.verificarOido(
        storedFeatures,
        storedFeatures,
      );
      expect(resultPositivo, true);
    });
  });

  group('Pruebas de rendimiento - Verificación biométrica', () {
    test('Tiempo de verificación menor a 500ms', () async {
      final biometricVerification = BiometricVerification(
        identificador: identificador,
        selected: ['Voz', 'Oído'],
      );

      final stopwatch = Stopwatch()..start();
      await biometricVerification.verificarOido(
        storedFeatures,
        currentFeaturesSuccess,
      );
      stopwatch.stop();

      print('⏱️ Tiempo de verificación: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
