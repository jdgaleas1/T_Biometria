import 'package:flutter_test/flutter_test.dart';
import 'package:tesisprueba/screens/biometric_verification.dart';
import 'package:tesisprueba/screens/biometric_db_helper.dart';

void main() {
  // Grupo 1: Pruebas unitarias (verificación de comparación biométrica)
  group('Pruebas unitarias - Comparación de características biométricas', () {
    test('Verificación de Oído - Comparación exitosa', () async {
      final storedFeatures = [0.8, 0.6, 0.9];
      final currentFeatures = [0.8, 0.6, 0.8];

      final biometricVerification = BiometricVerification(
        email: 'user@example.com',
        selected: ['Voz', 'Oído'],
      );

      final result = await biometricVerification.verificarOido(
        storedFeatures,
        currentFeatures,
      );
      expect(result, true);
    });

    test('Verificación de Oído - Comparación fallida', () async {
      final storedFeatures = [0.8, 0.6, 0.9];
      final currentFeatures = [0.2, 0.3, 0.4];

      final biometricVerification = BiometricVerification(
        email: 'user@example.com',
        selected: ['Voz', 'Oído'],
      );

      final result = await biometricVerification.verificarOido(
        storedFeatures,
        currentFeatures,
      );
      expect(result, false);
    });
  });

  // Grupo 2: Pruebas de integración (base de datos y biometría)
  group('Pruebas de integración - Base de datos y módulos biométricos', () {
    test('Integración de base de datos y módulos biométricos', () async {
      final storedFeatures = [0.8, 0.6, 0.9];
      final email = 'user@example.com';
      final modality = 'ear';

      await BiometricDBHelper().insertTemplate(email, modality, storedFeatures);

      final retrievedFeatures =
          await BiometricDBHelper().getTemplate(email, modality);

      expect(retrievedFeatures, equals(storedFeatures));
    });
  });

  // Grupo 3: Pruebas de validación biométrica
  group('Pruebas de validación - Falsos positivos y negativos', () {
    test('Tasa de falsos positivos/negativos', () async {
      final storedFeatures = [0.8, 0.6, 0.9];
      final fakeFeatures = [0.1, 0.2, 0.3];

      final biometricVerification = BiometricVerification(
        email: 'user@example.com',
        selected: ['Voz', 'Oído'],
      );

      final result = await biometricVerification.verificarOido(
        storedFeatures,
        fakeFeatures,
      );
      expect(result, false);

      final validFeatures = [0.8, 0.6, 0.9];
      final validResult = await biometricVerification.verificarOido(
        storedFeatures,
        validFeatures,
      );
      expect(validResult, true);
    });
  });

  // Grupo 4: Pruebas de rendimiento
  group('Pruebas de rendimiento - Verificación biométrica', () {
    test('Tiempo de verificación de oído menor a 500ms', () async {
      final storedFeatures = [0.8, 0.6, 0.9];
      final currentFeatures = [0.8, 0.6, 0.8];

      final biometricVerification = BiometricVerification(
        email: 'user@example.com',
        selected: ['Voz', 'Oído'],
      );

      final stopwatch = Stopwatch()..start();
      await biometricVerification.verificarOido(
        storedFeatures,
        currentFeatures,
      );
      stopwatch.stop();

      print(
          'Tiempo de verificación de oído: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
