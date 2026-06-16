// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  id: json['id'] as String,
  provider: json['provider'] as String?,
  nickname: json['nickname'] as String,
  email: json['email'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': instance.provider,
      'nickname': instance.nickname,
      'email': instance.email,
      'profileImageUrl': instance.profileImageUrl,
      'createdAt': instance.createdAt,
    };
