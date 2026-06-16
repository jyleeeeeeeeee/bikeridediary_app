import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    // colorSchemeSeed: 앱 전체 색상의 기준이 되는 시드 컬러
    // Material 3가 이 색상을 기반으로 primary, secondary, surface 등을 자동 생성
    // 예: Colors.blue, Colors.teal, Color(0xFF1A73E8) 등
    colorSchemeSeed: Colors.blue, // ← 바이크 라이딩 앱에 어울리는 색상으로 변경

    // appBarTheme: 상단 앱바의 기본 스타일
    // centerTitle: 제목 위치 (true=가운데, false=왼쪽)
    // elevation: 그림자 깊이 (0이면 플랫)
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}
