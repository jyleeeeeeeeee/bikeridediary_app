import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    // if (kIsWeb) return 'http://localhost:8081';
    // if (Platform.isAndroid) return 'http://localhost:8081';
    // if (Platform.isIOS) return 'http://192.168.0.46:8081';
    return 'http://localhost:8081';
  }

  static const String apiPrefix = '/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
