import 'dart:ffi';
import 'package:ffi/ffi.dart';

class BiometriaService {
  static late DynamicLibrary biometriaLib;

  static void loadLibrary() {
    biometriaLib = DynamicLibrary.open('libbiometria.so'); // Android
  }

  static void procesarVoz() {
    final func = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_voz');
    func();
  }

  static void procesarOido() {
    final func = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_oido');
    func();
  }

  static void procesarIris() {
    final func = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_iris');
    func();
  }

  static void procesarRostro() {
    final func = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_rostro');
    func();
  }

  static void procesarPalma() {
    final func = biometriaLib
        .lookupFunction<Void Function(), void Function()>('procesar_palma');
    func();
  }
}
