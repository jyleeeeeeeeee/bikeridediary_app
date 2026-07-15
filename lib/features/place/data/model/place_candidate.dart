/// 백엔드 `GET /api/v1/places/search-external` 응답 항목.
/// Naver 지역검색 결과를 도메인 형태로 매핑한 값 (좌표는 WGS84).
class PlaceCandidate {
  final String name;
  final String? naverCategory; // 참고용 (예: "여행>관광,명소")
  final double latitude;
  final double longitude;
  final String? address;
  final String? roadAddress;

  const PlaceCandidate({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.naverCategory,
    this.address,
    this.roadAddress,
  });

  factory PlaceCandidate.fromJson(Map<String, dynamic> json) {
    return PlaceCandidate(
      name: json['name'] as String,
      naverCategory: json['naverCategory'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      roadAddress: json['roadAddress'] as String?,
    );
  }
}
