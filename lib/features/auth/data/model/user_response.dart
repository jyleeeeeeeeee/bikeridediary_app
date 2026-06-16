import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

// Spring의 UserResponse record에 대응
// 서버에서 받는 사용자 정보
@JsonSerializable()
class UserResponse {
  final String id;
  final String? provider;         // nullable — 이메일 가입이면 null
  final String nickname;
  final String email;
  final String? profileImageUrl;  // nullable — 프로필 사진 없을 수 있음
  final String createdAt;

  UserResponse({
    required this.id,
    this.provider,                // required 없음 = 선택 파라미터 (null 허용)
    required this.nickname,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
  });

  // JSON Map → Dart 객체 (API 응답 받을 때)
  // Response이므로 fromJson만 필요
  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}
