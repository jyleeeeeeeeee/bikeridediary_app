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
import '../../features/maintenance/presentation/schedule_detail_screen.dart';
import '../../features/maintenance/presentation/schedule_form_screen.dart';
import '../../features/fueling/presentation/fueling_list_screen.dart';
import '../../features/fueling/presentation/fueling_form_screen.dart';
import '../../features/fueling/data/model/fueling_response.dart';
import '../../features/settings/presentation/settings_screen.dart';

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
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

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
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: 내 바이크 (includes maintenance and schedule sub-routes)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bikes',
                builder: (_, __) => const BikeListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const BikeRegistrationScreen(),
                  ),
                  GoRoute(
                    path: ':bikeId',
                    builder: (_, state) => BikeDetailScreen(
                      bikeId: state.pathParameters['bikeId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => BikeFormScreen(
                          bike: state.extra as BikeResponse?,
                        ),
                      ),

                      // 정비 기록
                      GoRoute(
                        path: 'maintenances',
                        builder: (_, state) => MaintenanceListScreen(
                          bikeId: state.pathParameters['bikeId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (_, state) => MaintenanceFormScreen(
                              bikeId: state.pathParameters['bikeId']!,
                            ),
                          ),
                          GoRoute(
                            path: ':maintenanceId',
                            builder: (_, state) => MaintenanceDetailScreen(
                              bikeId: state.pathParameters['bikeId']!,
                              maintenanceId:
                                  state.pathParameters['maintenanceId']!,
                            ),
                            routes: [
                              GoRoute(
                                path: 'edit',
                                builder: (_, state) => MaintenanceFormScreen(
                                  bikeId: state.pathParameters['bikeId']!,
                                  maintenance:
                                      state.extra as MaintenanceResponse?,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 정비 스케줄
                      GoRoute(
                        path: 'schedules',
                        redirect: (_, __) => null,
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (_, state) => ScheduleFormScreen(
                              bikeId: state.pathParameters['bikeId']!,
                            ),
                          ),
                          GoRoute(
                            path: ':scheduleId',
                            builder: (_, state) => ScheduleDetailScreen(
                              bikeId: state.pathParameters['bikeId']!,
                              scheduleId:
                                  state.pathParameters['scheduleId']!,
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

          // Branch 2: 주유 기록
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fuel',
                builder: (_, __) => const FuelingListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const FuelingFormScreen(),
                  ),
                  GoRoute(
                    path: ':fuelingId/edit',
                    builder: (_, state) => FuelingFormScreen(
                      fueling: state.extra as FuelingResponse?,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: 설정
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
