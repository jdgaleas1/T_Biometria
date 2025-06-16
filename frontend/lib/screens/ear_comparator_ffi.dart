import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef CompareEarFeaturesNative = ffi.Double Function(
    ffi.Pointer<ffi.Double> stored,
    ffi.Pointer<ffi.Double> current,
    ffi.Int32 length);

typedef CompareEarFeaturesDart = double Function(ffi.Pointer<ffi.Double> stored,
    ffi.Pointer<ffi.Double> current, int length);

class EarComparatorFFI {
  static final _lib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libear_comparator.so")
      : ffi.DynamicLibrary.process();

  static final CompareEarFeaturesDart compareEarFeatures = _lib
      .lookup<ffi.NativeFunction<CompareEarFeaturesNative>>(
          'compare_ear_features')
      .asFunction();
}
