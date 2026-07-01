import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/auth/domain/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
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
      // 로컬 저장소 sync — 등록된 도메인 순회. Phase 3에서 도메인들이 register 됨.
      await ref.read(syncEngineProvider).startAutoSync();
    });
  }

  @override
  Widget build(BuildContext context) {
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
