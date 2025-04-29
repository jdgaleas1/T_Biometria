import 'dart:ffi';
import 'package:ffi/ffi.dart';

class BiometriaService {
  static late DynamicLibrary biometriaLib;

  static void loadLibrary() {
    biometriaLib = DynamicLibrary.open('libbiometria.so'); // Android
    // biometriaLib = DynamicLibrary.open('libbiometria.a');  // iOS
  }

  static void procesarVoz() {
    final procesarVoz = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_voz');
    procesarVoz();
  }
}
