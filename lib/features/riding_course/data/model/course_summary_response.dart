// 코스 목록 아이템용 요약 응답 모델.
// 내 코스 탭 / 탐색 탭 리스트에서 사용.

/// 코스 목록 아이템 응답 DTO.
class CourseSummaryResponse {
  final String id;
  final String name;           // 코스명
  final int distanceMeters;    // 거리 (미터). km = distanceMeters / 1000
  final String authorNickname; // 작성자 닉네임 (시드 코스는 빈 문자열)
  final bool ownedByMe;        // true이면 내가 만든 코스
  final bool isFavorited;      // true이면 즐겨찾기 등록된 코스

  const CourseSummaryResponse({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.authorNickname,
    required this.ownedByMe,
    required this.isFavorited,
  });

  /// isFavorited 상태만 변경한 복사본 반환 (낙관적 업데이트용).
  CourseSummaryResponse copyWithFavorited(bool favorited) {
    return CourseSummaryResponse(
      id: id,
      name: name,
      distanceMeters: distanceMeters,
      authorNickname: authorNickname,
      ownedByMe: ownedByMe,
      isFavorited: favorited,
    );
  }

  factory CourseSummaryResponse.fromJson(Map<String, dynamic> json) {
    return CourseSummaryResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      distanceMeters: json['distanceMeters'] as int,
      authorNickname: (json['authorNickname'] as String?) ?? '',
      ownedByMe: json['ownedByMe'] as bool? ?? false,
      isFavorited: json['isFavorited'] as bool? ?? false,
    );
  }

  /// 화면 표시용 거리 문자열. 예: "128.4 km"
  String get distanceLabel {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}
