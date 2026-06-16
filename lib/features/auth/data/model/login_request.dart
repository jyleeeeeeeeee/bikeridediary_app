import 'package:json_annotation/json_annotation.dart';

// build_runner가 생성할 파일 연결
// 파일명 규칙: 현재파일명.g.dart
part 'login_request.g.dart';

// Spring의 LoginRequest record와 동일한 역할
// @JsonSerializable: Jackson의 @JsonProperty처럼 JSON 변환 코드를 자동 생성
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  // required: 이 파라미터는 반드시 전달해야 함 (Java의 @NotNull)
  // this.email: 파라미터를 받아서 바로 필드에 할당 (생성자 축약 문법)
  LoginRequest({required this.email, required this.password});

  // Dart 객체 → JSON Map (API 요청 body에 실림)
  // _$LoginRequestToJson: .g.dart에 자동 생성되는 함수
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
