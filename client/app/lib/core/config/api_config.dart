import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// API Configuration
class ApiConfig {
  ApiConfig._();

  /// Backend base URL, resolved per platform so the same build works on
  /// web, the Android emulator and desktop without manual edits.
  ///
  /// For a physical Android device on the same Wi-Fi, replace the Android
  /// branch below with your machine's LAN IP (`ip addr show` on Linux).
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080'; // Android emulator → host loopback
      }
      return 'http://localhost:8080'; // iOS simulator, Linux, macOS, Windows
    } catch (_) {
      return 'http://localhost:8080';
    }
  }
}
