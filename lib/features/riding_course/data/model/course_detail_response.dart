// 코스 상세 응답 모델.
// 경유지 목록과 지도 폴리라인 path 데이터를 포함.

import 'course_waypoint_response.dart';

/// 코스 상세 응답 DTO.
class CourseDetailResponse {
  final String id;
  final String name;
  final int distanceMeters;
  final String authorNickname; // 시드 코스는 빈 문자열("")
  final bool ownedByMe;
  final bool isFavorited;
  final List<CourseWaypointResponse> waypoints;

  /// 서버가 JSON 문자열 "[[lng,lat],[lng,lat],...]" 형태로 전달.
  /// null이면 경유지 좌표로 폴리라인 직접 구성.
  final String? pathJson;

  const CourseDetailResponse({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.authorNickname,
    required this.ownedByMe,
    required this.isFavorited,
    required this.waypoints,
    this.pathJson,
  });

  /// isFavorited 상태만 변경한 복사본.
  CourseDetailResponse copyWithFavorited(bool favorited) {
    return CourseDetailResponse(
      id: id,
      name: name,
      distanceMeters: distanceMeters,
      authorNickname: authorNickname,
      ownedByMe: ownedByMe,
      isFavorited: favorited,
      waypoints: waypoints,
      pathJson: pathJson,
    );
  }

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawWaypoints = json['waypoints'] as List? ?? [];
    final waypoints = rawWaypoints
        .map((e) =>
            CourseWaypointResponse.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.seq.compareTo(b.seq)); // seq 오름차순 정렬

    return CourseDetailResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      distanceMeters: json['distanceMeters'] as int,
      authorNickname: (json['authorNickname'] as String?) ?? '',
      ownedByMe: json['ownedByMe'] as bool? ?? false,
      isFavorited: json['isFavorited'] as bool? ?? false,
      waypoints: waypoints,
      pathJson: json['path'] as String?,
    );
  }

  /// 화면 표시용 거리 문자열.
  String get distanceLabel {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}
