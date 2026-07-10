import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/bike/domain/bike_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
  // 네이버 지도 SDK 초기화 — .env에 NAVER_MAP_CLIENT_ID 필요.
  // 네이버 클라우드 플랫폼 콘솔에서 발급받은 Client ID를 넣으면 지도 타일이 로드됨.
  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '',
    onAuthFailed: (ex) {
      debugPrint('네이버 지도 인증 실패: $ex');
    },
  );
  runApp(const ProviderScope(child: BrdApp()));
}

class BrdApp extends ConsumerStatefulWidget {
  const BrdApp({super.key});

  @override
  ConsumerState<BrdApp> createState() => _BrdAppState();
}

class _BrdAppState extends ConsumerState<BrdApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authProvider.notifier).checkAuth();
      // 도메인 sync 서비스 등록 — 각 도메인이 로컬 우선 이전 완료 시점에 여기에 추가.
      final engine = ref.read(syncEngineProvider);
      engine.register(ref.read(bikeSyncServiceProvider));
      // 초기 pull: 로그인 유저이고 로컬이 비어 있으면 서버에서 pull.
      final auth = ref.read(authProvider);
      if (auth.status == AuthStatus.authenticated && !auth.isLocalGuest) {
        await ref.read(bikeSyncServiceProvider).pullFromServerIfEmpty();
      }
      await engine.startAutoSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 상태 전이 감지 — 앱 실행 중 로그인이 발생하면 서버에서 로컬로 pull.
    ref.listen<AuthState>(authProvider, (prev, next) async {
      final justLoggedIn = (prev == null ||
              prev.status != AuthStatus.authenticated) &&
          next.status == AuthStatus.authenticated;
      if (justLoggedIn && !next.isLocalGuest) {
        await ref.read(bikeSyncServiceProvider).pullFromServerIfEmpty();
        await ref.read(syncEngineProvider).syncAll();
      }
    });

    final authState = ref.watch(authProvider);
    final router = ref.watch(appRouterProvider);

    if (authState.status == AuthStatus.initial) {
      return MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: '바라다',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
