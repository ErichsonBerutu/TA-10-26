import 'package:flutter/foundation.dart' show kIsWeb;

// Hanya import dart:io jika bukan Web (dart:io tidak tersedia di Flutter Web)
import 'api_config_stub.dart'
    if (dart.library.io) 'api_config_native.dart' as NativeConfig;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web: gunakan URL relatif atau localhost backend
      return "http://localhost:8000/api";
    }
    // Delegasi ke helper native (Android/iOS/Desktop)
    return NativeConfig.nativeBaseUrl;
  }
}
