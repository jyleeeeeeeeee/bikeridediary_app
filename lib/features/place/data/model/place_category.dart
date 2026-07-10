import 'package:flutter/material.dart';

/// 지도 카테고리. 서버 enum과 매핑 + UI 표시 정보.
enum PlaceCategory {
  landmark('LANDMARK', '명소', Icons.landscape_outlined, Color(0xFF34C759)),
  cafe('CAFE', '바이크 카페', Icons.local_cafe_outlined, Color(0xFFAF52DE)),
  serviceCenter('SERVICE_CENTER', '정비 센터', Icons.build_outlined, Color(0xFFFF3B30)),
  gasStation('GAS_STATION', '주유소', Icons.local_gas_station_outlined, Color(0xFFFF9500));

  final String serverCode;
  final String label;
  final IconData icon;
  final Color color;

  const PlaceCategory(this.serverCode, this.label, this.icon, this.color);

  static PlaceCategory? fromServer(String code) {
    for (final c in PlaceCategory.values) {
      if (c.serverCode == code) return c;
    }
    return null;
  }
}
