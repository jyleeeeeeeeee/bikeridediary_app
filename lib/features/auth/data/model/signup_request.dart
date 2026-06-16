import 'package:json_annotation/json_annotation.dart';

part 'signup_request.g.dart';

@JsonSerializable()
class SignupRequest {
  final String email;
  final String password;
  final String nickname;
  
  SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);
  
}
