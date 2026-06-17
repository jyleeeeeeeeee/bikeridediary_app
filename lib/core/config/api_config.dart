import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // 웹에서는 localhost, 에뮬레이터에서는 10.0.2.2 사용
  static String get baseUrl => kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8080';
  static const String apiPrefix = '/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
