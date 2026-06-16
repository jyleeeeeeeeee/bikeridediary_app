enum BikeCategory {
  SPORT,
  NAKED,
  TOURING,
  OFFROAD,
  SCOOTER,
  OTHER;

  String get displayName {
    switch (this) {
      case SPORT: return '스포츠';
      case NAKED: return '네이키드';
      case TOURING: return '투어링';
      case OFFROAD: return '오프로드';
      case SCOOTER: return '스쿠터';
      case OTHER: return '기타';
    }
  }
}
