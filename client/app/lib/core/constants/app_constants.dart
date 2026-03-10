import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'LiftUp';
  static const String appVersion = '1.0.0';

  // API Configuration
  static String get baseUrl {
    // Web: toujours utiliser localhost
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    
    // Mobile/Desktop: dépend de la plateforme
    try {
      if (Platform.isAndroid) {
        // Android Physical Device: IP du PC Windows sur le réseau local
        return 'http://10.73.189.87:8080';
      } else if (Platform.isIOS) {
        // iOS Simulator
        return 'http://localhost:8080';
      } else {
        // Linux, macOS, Windows
        return 'http://localhost:8080';
      }
    } catch (e) {
      // Fallback
      return 'http://localhost:8080';
    }
  }
  
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 16.0;
}
