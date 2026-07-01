import 'package:flutter/material.dart';

/// 뱅킹 측정 화면 전용 팔레트.
/// 자동차 계기판 감성을 살리기 위해 뱅킹 측정/세션 상세 화면만 다크 톤을 사용한다.
/// 앱 나머지 화면(홈/정비/주유 등)은 core/theme/app_theme.dart의 라이트 톤을 그대로 유지.
class BankingColors {
  static const primary = Color(0xFF007AFF);
  static const danger = Color(0xFFFF3B30);
  static const success = Color(0xFF34C759);
  static const yellow = Color(0xFFFFD60A);
  static const orange = Color(0xFFFF9500);

  static const bgDark = Color(0xFF0B0F19);
  static const bgCard = Color(0xFF1C2235);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E93A6);
}

/// 각도 절대값에 따른 위험도 색상 — 게이지, 최대각 표시, 텍스트 공통.
Color bankingZoneColor(double absAngle) {
  if (absAngle < 15) return BankingColors.success;
  if (absAngle < 30) return BankingColors.yellow;
  if (absAngle < 45) return BankingColors.orange;
  return BankingColors.danger;
}
