import 'dart:math';

class BiometricHelper {
  static final List<String> todasLasBiometrias = [
    'Voz',
    'Oído',
    'Iris',
    'Rostro',
    'Palma',
  ];

  /// Devuelve 2 biometrías seleccionadas aleatoriamente
  static List<String> seleccionarAleatoriamente({int cantidad = 2}) {
    final copia = List<String>.from(todasLasBiometrias);
    copia.shuffle(Random());
    return copia.take(cantidad).toList();
  }

  /// Devuelve un mapa vacío para guardar el estado de cada biometría
  static Map<String, bool> estadoInicial() {
    return {
      'Voz': false,
      'Oído': false,
      'Iris': false,
      'Rostro': false,
      'Palma': false,
    };
  }

  /// Verifica si todas las biometrías han sido completadas
  static bool todasCompletadas(Map<String, bool> biometria) {
    return biometria.values.every((completado) => completado);
  }
}
