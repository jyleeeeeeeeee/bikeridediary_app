// 연료 종류 enum — 백엔드 FuelType과 동기화
enum FuelType {
  REGULAR,
  PREMIUM,
  DIESEL;

  String get displayName {
    switch (this) {
      case REGULAR:
        return '일반유';
      case PREMIUM:
        return '고급유';
      case DIESEL:
        return '경유';
    }
  }
}
