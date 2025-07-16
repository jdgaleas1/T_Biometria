import 'dart:ffi' as ffi;
import 'dart:io';

typedef CompareVoiceFeaturesNative = ffi.Double Function(
    ffi.Pointer<ffi.Double>, ffi.Pointer<ffi.Double>, ffi.Int32);

typedef CompareVoiceFeaturesDart = double Function(
    ffi.Pointer<ffi.Double>, ffi.Pointer<ffi.Double>, int);

class VoiceComparatorFFI {
  static final _lib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libvoice_comparator.so")
      : ffi.DynamicLibrary.process();

  static final CompareVoiceFeaturesDart compareVoiceFeatures = _lib
      .lookup<ffi.NativeFunction<CompareVoiceFeaturesNative>>(
          'compare_voice_features')
      .asFunction();
}
