/// 지도 카테고리. 서버 place_categories.category_code와 매핑 + UI 표시 정보.
/// enum 선언 순서 = display_order 오름차순 (명소 1, 카페 2, 식당 3, 센터 9999, 기타).
enum PlaceCategory {
  famous('FAMOUS', '명소', '📸'),
  cafe('CAFE', '카페', '☕'),
  restaurant('RESTAURANT', '식당', '🍽️'),
  service('SERVICE', '센터', '🔧'),
  other('OTHER', '기타', '📌');

  final String serverCode;
  final String label;
  final String icon;

  const PlaceCategory(this.serverCode, this.label, this.icon);

  static PlaceCategory? fromServer(String code) {
    for (final c in PlaceCategory.values) {
      if (c.serverCode == code) return c;
    }
    return null;
  }
}
