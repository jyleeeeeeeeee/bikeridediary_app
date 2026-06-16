import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/auth/domain/auth_state.dart';

void main() {
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
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
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
