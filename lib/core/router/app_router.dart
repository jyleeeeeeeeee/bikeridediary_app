import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'main_shell.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/bike/data/model/bike_response.dart';
import '../../features/bike/presentation/bike_detail_screen.dart';
import '../../features/bike/presentation/bike_form_screen.dart';
import '../../features/bike/presentation/bike_list_screen.dart';
import '../../features/bike/presentation/bike_registration_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/maintenance/data/model/maintenance_response.dart';
import '../../features/maintenance/presentation/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/maintenance_form_screen.dart';
import '../../features/maintenance/presentation/maintenance_list_screen.dart';
import '../../features/maintenance/presentation/maintenance_tab_screen.dart';
import '../../features/maintenance/presentation/schedule_detail_screen.dart';
import '../../features/maintenance/presentation/schedule_form_screen.dart';
import '../../features/fueling/presentation/fueling_list_screen.dart';
import '../../features/fueling/presentation/fueling_form_screen.dart';
import '../../features/fueling/data/model/fueling_response.dart';
import '../../features/settings/presentation/settings_screen.dart';

Page<void> _smoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: _EdgeSwipeBack(child: child),
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}

class _EdgeSwipeBack extends StatelessWidget {
  final Widget child;
  const _EdgeSwipeBack({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 300) {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ),
      ],
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAllowed = authState.status == AuthStatus.authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isAllowed && !isAuthRoute) return '/login';
      if (isAllowed && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes — outside the shell (no bottom nav)
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),

      // Shell routes — wrapped with BottomNavigationBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: 홈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: 정비
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/maintenance',
                builder: (_, _) => const MaintenanceTabScreen(),
              ),
            ],
          ),

          // Branch 2: 내 바이크 (includes maintenance and schedule sub-routes)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bikes',
                builder: (_, _) => const BikeListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) =>
                        _smoothPage(state, const BikeRegistrationScreen()),
                  ),
                  GoRoute(
                    path: ':bikeId',
                    pageBuilder: (_, state) => _smoothPage(
                      state,
                      BikeDetailScreen(
                        bikeId: state.pathParameters['bikeId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (_, state) => _smoothPage(
                          state,
                          BikeFormScreen(
                            bike: state.extra as BikeResponse?,
                          ),
                        ),
                      ),

                      // 정비 기록
                      GoRoute(
                        path: 'maintenances',
                        pageBuilder: (_, state) => _smoothPage(
                          state,
                          MaintenanceListScreen(
                            bikeId: state.pathParameters['bikeId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'new',
                            pageBuilder: (_, state) => _smoothPage(
                              state,
                              MaintenanceFormScreen(
                                bikeId: state.pathParameters['bikeId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':maintenanceId',
                            pageBuilder: (_, state) => _smoothPage(
                              state,
                              MaintenanceDetailScreen(
                                bikeId: state.pathParameters['bikeId']!,
                                maintenanceId:
                                    state.pathParameters['maintenanceId']!,
                              ),
                            ),
                            routes: [
                              GoRoute(
                                path: 'edit',
                                pageBuilder: (_, state) => _smoothPage(
                                  state,
                                  MaintenanceFormScreen(
                                    bikeId: state.pathParameters['bikeId']!,
                                    maintenance:
                                        state.extra as MaintenanceResponse?,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 정비 스케줄
                      GoRoute(
                        path: 'schedules',
                        redirect: (_, _) => null,
                        routes: [
                          GoRoute(
                            path: 'new',
                            pageBuilder: (_, state) => _smoothPage(
                              state,
                              ScheduleFormScreen(
                                bikeId: state.pathParameters['bikeId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':scheduleId',
                            pageBuilder: (_, state) => _smoothPage(
                              state,
                              ScheduleDetailScreen(
                                bikeId: state.pathParameters['bikeId']!,
                                scheduleId:
                                    state.pathParameters['scheduleId']!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: 주유 기록
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fuel',
                builder: (_, _) => const FuelingListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) =>
                        _smoothPage(state, const FuelingFormScreen()),
                  ),
                  GoRoute(
                    path: ':fuelingId/edit',
                    pageBuilder: (_, state) => _smoothPage(
                      state,
                      FuelingFormScreen(
                        fueling: state.extra as FuelingResponse?,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: 설정
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
