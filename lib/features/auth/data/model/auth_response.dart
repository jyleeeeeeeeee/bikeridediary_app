import 'package:json_annotation/json_annotation.dart';
import 'user_response.dart';

part 'auth_response.g.dart';

// 로그인/회원가입 성공 시 서버 응답
// accessToken + refreshToken + 사용자 정보를 한 번에 받음
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
