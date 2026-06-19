import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/model/token_response.dart';

typedef ForceLogoutCallback = void Function();

ForceLogoutCallback? _onForceLogout;

void setForceLogoutCallback(ForceLogoutCallback callback) {
  _onForceLogout = callback;
}

Completer<bool>? _tokenRefreshCompleter;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}',
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode != 401) {
        return handler.next(error);
      }

      if (_tokenRefreshCompleter != null) {
        final success = await _tokenRefreshCompleter!.future;
        if (success) {
          final newToken = await TokenStorage.getAccessToken();
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(error.requestOptions);
          return handler.resolve(response);
        }
        return handler.next(error);
      }

      _tokenRefreshCompleter = Completer<bool>();

      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) throw Exception('No refresh token');

        final refreshDio = Dio(BaseOptions(
          baseUrl: '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}',
          headers: {'Content-Type': 'application/json'},
        ));
        final response = await refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        final tokens = TokenResponse.fromJson(response.data['data']);

        await TokenStorage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );

        _tokenRefreshCompleter!.complete(true);
        _tokenRefreshCompleter = null;

        error.requestOptions.headers['Authorization'] =
            'Bearer ${tokens.accessToken}';
        final retryResponse = await dio.fetch(error.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        _tokenRefreshCompleter?.complete(false);
        _tokenRefreshCompleter = null;

        await TokenStorage.clear();
        _onForceLogout?.call();
        return handler.next(error);
      }
    },
  ));

  return dio;
});
