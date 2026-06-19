import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/model/login_request.dart';
import '../data/model/signup_request.dart';
import '../data/repository/auth_repository.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.watch(authRepositoryProvider));
  setForceLogoutCallback(() => notifier.forceLogout());
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> signup(String email, String password, String nickname) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.signup(
        SignupRequest(email: email, password: password, nickname: nickname),
      );
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await TokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    TokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.guestSignup();
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return data['message'] as String;
    }
    return '네트워크 오류가 발생했습니다';
  }
}
