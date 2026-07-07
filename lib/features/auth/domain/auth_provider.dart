
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/local/app_database.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../bike/domain/bike_provider.dart';
import '../../fueling/domain/fueling_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';
import '../data/model/login_request.dart';
import '../data/model/signup_request.dart';
import '../data/repository/auth_repository.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.watch(authRepositoryProvider), ref);
  setForceLogoutCallback(() => notifier.forceLogout());
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState());

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
      _invalidateAllData();
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
      _invalidateAllData();
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> logout() async {
    try {
      if (!state.isLocalGuest) {
        await _repository.logout();
      }
    } catch (_) {}
    await TokenStorage.clear();
    // 한 기기 = 한 유저 전제. 로그아웃 시 로컬 도메인 데이터 전체 삭제
    // → 재로그인 또는 다른 유저 로그인 시 서버에서 새로 pull.
    await AppDatabase.clearAll();
    _invalidateAllData();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceLogout() {
    TokenStorage.clear();
    // fire-and-forget — 강제 로그아웃 흐름은 UI가 이미 진행 중일 수 있어 await 없음.
    AppDatabase.clearAll();
    _invalidateAllData();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _invalidateAllData() {
    _ref.invalidate(bikeListProvider);
    _ref.invalidate(bikeDetailProvider);
    _ref.invalidate(fuelingListProvider);
    _ref.invalidate(fuelingStatsProvider);
    _ref.invalidate(maintenanceListProvider);
    _ref.invalidate(maintenanceDetailProvider);
    _ref.invalidate(scheduleListProvider);
  }

  Future<void> loginWithKakao() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final response = await _repository.socialLogin('kakao', token.accessToken);
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      _invalidateAllData();
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '카카오 로그인에 실패했습니다');
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
      ).signIn();
      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: '구글 인증 토큰을 받지 못했습니다');
        return;
      }

      final response = await _repository.socialLogin('google', idToken);
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      _invalidateAllData();
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '구글 로그인에 실패했습니다');
    }
  }

  Future<void> loginWithApple() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Apple 인증 토큰을 받지 못했습니다');
        return;
      }

      String? name;
      if (credential.givenName != null || credential.familyName != null) {
        name = [credential.familyName, credential.givenName]
            .where((s) => s != null && s.isNotEmpty)
            .join('');
      }

      final response = await _repository.socialLogin('apple', identityToken, name: name);
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      _invalidateAllData();
      state = state.copyWith(status: AuthStatus.authenticated, user: response.user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } on SignInWithAppleAuthorizationException {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Apple 로그인에 실패했습니다');
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.guestSignup();
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      _invalidateAllData();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        isLocalGuest: false,
      );
    } on DioException catch (e) {
      // 네트워크 실패 시 로컬 게스트로 fallback — 서버 통신 없이 앱 진입.
      // 로컬 우선 도메인(뱅킹)만 정상 사용 가능. 다른 서버 도메인은 UI에서 제한.
      final isNetworkError = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      if (isNetworkError) {
        _invalidateAllData();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: null,
          isLocalGuest: true,
        );
        return;
      }
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
