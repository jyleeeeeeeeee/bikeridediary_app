import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/bike/data/model/bike_response.dart';
import '../../features/bike/presentation/bike_detail_screen.dart';
import '../../features/bike/presentation/bike_form_screen.dart';
import '../../features/bike/presentation/bike_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/maintenance/data/model/maintenance_response.dart';
import '../../features/maintenance/presentation/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/maintenance_form_screen.dart';
import '../../features/maintenance/presentation/maintenance_list_screen.dart';
import '../../features/maintenance/presentation/schedule_detail_screen.dart';
import '../../features/maintenance/presentation/schedule_form_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),

      // 바이크
      GoRoute(path: '/bikes', builder: (_, __) => const BikeListScreen()),
      GoRoute(path: '/bikes/new', builder: (_, __) => const BikeFormScreen()),
      GoRoute(
        path: '/bikes/:bikeId',
        builder: (_, state) => BikeDetailScreen(bikeId: state.pathParameters['bikeId']!),
      ),
      GoRoute(
        path: '/bikes/:bikeId/edit',
        builder: (_, state) => BikeFormScreen(bike: state.extra as BikeResponse?),
      ),

      // 정비
      GoRoute(
        path: '/bikes/:bikeId/maintenances',
        builder: (_, state) => MaintenanceListScreen(bikeId: state.pathParameters['bikeId']!),
      ),
      GoRoute(
        path: '/bikes/:bikeId/maintenances/new',
        builder: (_, state) => MaintenanceFormScreen(bikeId: state.pathParameters['bikeId']!),
      ),
      GoRoute(
        path: '/bikes/:bikeId/maintenances/:maintenanceId',
        builder: (_, state) => MaintenanceDetailScreen(
          bikeId: state.pathParameters['bikeId']!,
          maintenanceId: state.pathParameters['maintenanceId']!,
        ),
      ),
      GoRoute(
        path: '/bikes/:bikeId/maintenances/:maintenanceId/edit',
        builder: (_, state) => MaintenanceFormScreen(
          bikeId: state.pathParameters['bikeId']!,
          maintenance: state.extra as MaintenanceResponse?,
        ),
      ),

      // 정비 스케줄
      GoRoute(
        path: '/bikes/:bikeId/schedules/new',
        builder: (_, state) => ScheduleFormScreen(bikeId: state.pathParameters['bikeId']!),
      ),
      GoRoute(
        path: '/bikes/:bikeId/schedules/:scheduleId',
        builder: (_, state) => ScheduleDetailScreen(
          bikeId: state.pathParameters['bikeId']!,
          scheduleId: state.pathParameters['scheduleId']!,
        ),
      ),
    ],
  );
});
