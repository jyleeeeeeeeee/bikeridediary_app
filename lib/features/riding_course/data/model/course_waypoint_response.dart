// 라이딩 코스의 경유지 응답 모델.
// role: START / VIA / END (백엔드 DB 값 그대로)
// seq: 오름차순 정렬 기준

/// 코스 경유지 단일 응답 DTO.
class CourseWaypointResponse {
  final String id;
  final int seq;              // 순서 (0부터 시작)
  final String role;          // START / VIA / END
  final String name;          // 경유지 표시 이름 (주소 등)
  final double latitude;
  final double longitude;
  final String? placeId;          // 등록된 place ID (임의 지점은 null)
  final String? placeCategoryCode; // place 카테고리 코드 (마커 아이콘 결정용, null 가능)

  const CourseWaypointResponse({
    required this.id,
    required this.seq,
    required this.role,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.placeCategoryCode,
  });

  factory CourseWaypointResponse.fromJson(Map<String, dynamic> json) {
    return CourseWaypointResponse(
      id: json['id'] as String,
      seq: json['seq'] as int,
      role: json['role'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String?,
      placeCategoryCode: json['placeCategoryCode'] as String?,
    );
  }
}
