import 'place_category.dart';

/// 서버 응답 모델. 주유소는 별도 station API를 쓰지만
/// 지도 UI 통합을 위해 이 모델로 컨버트해서 함께 표시한다.
class PlaceResponse {
  final String id;
  final String name;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final String? photoUrl;
  final String? phone;
  final String? kakaoPlaceId;
  final String? naverPlaceId;

  PlaceResponse({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.photoUrl,
    this.phone,
    this.kakaoPlaceId,
    this.naverPlaceId,
  });

  PlaceResponse copyWith({double? latitude, double? longitude}) {
    return PlaceResponse(
      id: id,
      name: name,
      category: category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address,
      description: description,
      photoUrl: photoUrl,
      phone: phone,
      kakaoPlaceId: kakaoPlaceId,
      naverPlaceId: naverPlaceId,
    );
  }

  factory PlaceResponse.fromJson(Map<String, dynamic> json) {
    return PlaceResponse(
      id: json['id'] as String,
      name: json['placeName'] as String,
      category:
          PlaceCategory.fromServer(json['category'] as String) ??
              PlaceCategory.famous,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? json['roadAddress'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
      kakaoPlaceId: json['kakaoPlaceId'] as String?,
      naverPlaceId: json['naverPlaceId'] as String?,
    );
  }
}
