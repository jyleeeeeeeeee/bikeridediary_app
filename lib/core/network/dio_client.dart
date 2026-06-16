import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';

// Dio HTTP 클라이언트 Provider — 앱 전체에서 하나의 인스턴스 공유
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}',
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  // 인터셉터: 매 요청마다 저장된 JWT 토큰을 Authorization 헤더에 자동 추가
  // Spring의 OncePerRequestFilter와 비슷한 역할
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      // TODO: 401 응답 시 토큰 갱신 로직 (auth 기능 구현 시 추가)
      handler.next(error);
    },
  ));

  return dio;
});
