enum MaintenanceType {
  ENGINE_OIL,
  CHAIN,
  FRONT_TIRE,
  FRONT_BRAKE_PAD,
  FRONT_BRAKE_FLUID,
  FRONT_SUSPENSION,
  REAR_TIRE,
  REAR_BRAKE_PAD,
  REAR_BRAKE_FLUID,
  REAR_SUSPENSION,
  BATTERY,
  SPARK_PLUG,
  AIR_FILTER,
  COOLANT,
  OTHER;

  String get displayName {
    switch (this) {
      case ENGINE_OIL: return '엔진 오일';
      case CHAIN: return '체인';
      case FRONT_TIRE: return '앞 타이어';
      case FRONT_BRAKE_PAD: return '앞 브레이크 패드';
      case FRONT_BRAKE_FLUID: return '앞 브레이크 액';
      case FRONT_SUSPENSION: return '앞 서스펜션 오일';
      case REAR_TIRE: return '뒷 타이어';
      case REAR_BRAKE_PAD: return '뒷 브레이크 패드';
      case REAR_BRAKE_FLUID: return '뒷 브레이크 액';
      case REAR_SUSPENSION: return '뒷 서스펜션 오일';
      case BATTERY: return '배터리';
      case SPARK_PLUG: return '점화플러그';
      case AIR_FILTER: return '에어필터';
      case COOLANT: return '냉각수';
      case OTHER: return '기타';
    }
  }
}
