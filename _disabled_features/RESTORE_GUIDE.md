# 비활성화된 기능 복구 가이드

GPS 위치 권한 관련 플레이스토어 출시 이슈로 인해 제거된 기능들입니다.
복구 시 아래 순서대로 진행하세요.

## 제거된 기능
1. **riding/** — 주행 기록 (GPS 실시간 트래킹)
2. **fueling/** — 주유 기록 (주유소 선택 시 GPS 사용)
3. **station/** — 주유소 검색 (GPS 기반 근처 주유소 조회, 평균 유가)

## 복구 절차

### 1. 기능 디렉토리 복원
```
cp -r _disabled_features/riding   lib/features/riding
cp -r _disabled_features/fueling  lib/features/fueling
cp -r _disabled_features/station  lib/features/station
```

### 2. pubspec.yaml — 패키지 복원
```yaml
dependencies:
  geolocator: ^14.0.2
  url_launcher: ^6.3.1
```

### 3. app_router.dart — 라우트 복원

import 추가:
```dart
import '../../features/fueling/presentation/fueling_list_screen.dart';
import '../../features/fueling/presentation/fueling_form_screen.dart';
import '../../features/fueling/data/model/fueling_response.dart';
import '../../features/station/presentation/station_search_screen.dart';
import '../../features/station/presentation/station_pick_screen.dart';
import '../../features/riding/presentation/course_list_screen.dart';
import '../../features/riding/presentation/course_detail_screen.dart';
import '../../features/riding/presentation/riding_record_screen.dart';
import '../../features/riding/presentation/riding_save_screen.dart';
import '../../features/riding/domain/riding_provider.dart';
```

Shell 바깥 라우트 추가 (auth routes 아래):
```dart
// Station search
GoRoute(path: '/stations', pageBuilder: (_, state) => _smoothPage(state, const StationSearchScreen())),
GoRoute(path: '/stations/pick', pageBuilder: (_, state) => _smoothPage(state, const StationPickScreen())),

// Riding
GoRoute(path: '/riding/record', pageBuilder: (_, state) => _smoothPage(state, const RidingRecordScreen())),
GoRoute(path: '/riding/save', pageBuilder: (_, state) => _smoothPage(state, RidingSaveScreen(ridingResult: state.extra as RidingState))),
GoRoute(path: '/riding', pageBuilder: (_, state) => _smoothPage(state, const CourseListScreen())),
GoRoute(path: '/riding/:courseId', pageBuilder: (_, state) => _smoothPage(state, CourseDetailScreen(courseId: state.pathParameters['courseId']!))),
```

Shell Branch 추가 (내 바이크 branch 뒤):
```dart
// Branch: 주유 기록
StatefulShellBranch(routes: [
  GoRoute(
    path: '/fuel',
    builder: (_, _) => const FuelingListScreen(),
    routes: [
      GoRoute(path: 'new', pageBuilder: (_, state) => _smoothPage(state, const FuelingFormScreen())),
      GoRoute(path: ':fuelingId/edit', pageBuilder: (_, state) => _smoothPage(state, FuelingFormScreen(fueling: state.extra as FuelingResponse?))),
    ],
  ),
]),
```

### 4. main_shell.dart — 하단 탭 복원
설정 탭 앞에 추가:
```dart
BottomNavigationBarItem(icon: Icon(Icons.local_gas_station_rounded), label: '주유'),
```

### 5. home_screen.dart — 헤더 유가 + 퀵메뉴 복원
- import: `station/data/model/avg_oil.dart`, `fueling/domain/fueling_provider.dart`, `station/domain/station_provider.dart`
- 헤더에 `avgOilPriceProvider` watch + `_OilPriceChip` 위젯
- `_QuickStatsRow`에 `fuelingStatsProvider` watch (평균 연비 카드)
- `_QuickActionsGrid`에 주유 기록, 주유소 검색 카드
- RefreshIndicator에 `fuelingStatsProvider`, `avgOilPriceProvider` invalidate

### 6. Android 권한
`AndroidManifest.xml`에 위치 권한이 이미 있으면 확인:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 7. 개인정보처리방침 필수
위치 데이터를 서버로 전송하므로:
- 개인정보처리방침 웹페이지 준비
- 앱 내 위치 데이터 전송 사전 동의 다이얼로그 구현
- 플레이스토어 데이터 안전 섹션 작성
