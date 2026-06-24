import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/auth_response.dart';
import '../model/login_request.dart';
import '../model/signup_request.dart';
import '../model/token_response.dart';

// AuthRepository Provider — Spring의 @Bean과 같은 역할
// ref.watch(authRepositoryProvider)로 어디서든 주입 가능
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // dioProvider에서 Dio 인스턴스를 가져옴 (Spring의 @Autowired)
  return AuthRepository(ref.watch(dioProvider));
});

// Spring의 AuthService가 외부 API를 호출하는 역할과 비슷
// 실제 HTTP 요청을 담당하는 계층
class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // 이메일 로그인
  // Spring 대응: authService.loginWithEmail(LoginRequest)
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post('/auth/login', data: request.toJson());
    // response.data는 ApiResponse 래퍼 전체 { "data": {...}, "success": true }
    // 실제 데이터는 response.data['data'] 안에 있음
    return AuthResponse.fromJson(response.data['data']);
  }

  // 이메일 회원가입
  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _dio.post('/auth/signup', data: request.toJson());
    return AuthResponse.fromJson(response.data['data']);
  }

  // 게스트 가입
  Future<AuthResponse> guestSignup() async {
    final response = await _dio.post('/auth/guest');
    return AuthResponse.fromJson(response.data['data']);
  }

  // 토큰 갱신
  Future<TokenResponse> refresh(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return TokenResponse.fromJson(response.data['data']);
  }

  // 소셜 로그인
  Future<AuthResponse> socialLogin(String provider, String credential, {String? name}) async {
    final response = await _dio.post(
      '/auth/login/$provider',
      data: {
        'credential': credential,
        'name': ?name,
      },
    );
    return AuthResponse.fromJson(response.data['data']);
  }

  // 로그아웃
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
