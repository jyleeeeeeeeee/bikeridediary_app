// 연료 종류 enum — 백엔드 FuelType과 동기화
enum FuelType {
  REGULAR,
  PREMIUM;

  String get displayName {
    switch (this) {
      case REGULAR:
        return '휘발유';
      case PREMIUM:
        return '고급휘발유';
    }
  }
}
