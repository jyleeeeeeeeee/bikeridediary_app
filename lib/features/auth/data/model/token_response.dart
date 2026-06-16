import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';

// 토큰 갱신(refresh) 시 서버 응답
// AuthResponse와 달리 user 정보 없이 토큰만 반환
@JsonSerializable()
class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);
}
