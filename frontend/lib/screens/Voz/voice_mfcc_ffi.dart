import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef ComputeVoiceMfccNative = ffi.Pointer<ffi.Double> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int32>);

typedef ComputeVoiceMfccDart = Pointer<Double> Function(
    Pointer<Utf8>, Pointer<ffi.Int32>);

typedef FreeMfccNative = ffi.Void Function(ffi.Pointer<ffi.Double>);
typedef FreeMfccDart = void Function(ffi.Pointer<ffi.Double>);

class VoiceMfccFFI {
  static final _lib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libvoice_mfcc.so")
      : ffi.DynamicLibrary.process();

  static final ComputeVoiceMfccDart computeVoiceMfcc = _lib
      .lookup<ffi.NativeFunction<ComputeVoiceMfccNative>>('compute_voice_mfcc')
      .asFunction();

  static final FreeMfccDart freeMfcc =
      _lib.lookup<ffi.NativeFunction<FreeMfccNative>>('free_mfcc').asFunction();

  static List<double> extractMfcc(String filePath) {
    final pathPtr = filePath.toNativeUtf8();
    final numCoefficientsPtr = calloc<ffi.Int32>();

    final mfccPtr = computeVoiceMfcc(pathPtr, numCoefficientsPtr);

    final numCoefficients = numCoefficientsPtr.value;
    final mfccList = List<double>.generate(
        numCoefficients, (i) => mfccPtr.elementAt(i).value);

    // Free memory
    freeMfcc(mfccPtr);
    calloc.free(pathPtr);
    calloc.free(numCoefficientsPtr);

    return mfccList;
  }
}
