import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/app_preferences.dart';
import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/auth_state.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/automation/presentation/automation_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/devices/presentation/device_detail_screen.dart';
import '../../features/energy/presentation/energy_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rooms/presentation/room_device.dart';
import '../../features/rooms/presentation/rooms_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingCompleted = ref
      .watch(appPreferencesProvider)
      .onboardingCompleted;

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(
        name: 'splash',
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'home',
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    name: 'device-detail',
                    path: 'devices/:deviceId',
                    builder: (context, state) => DeviceDetailScreen(
                      deviceId: state.pathParameters['deviceId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'rooms',
                path: '/rooms',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RoomsScreen()),
                routes: [
                  GoRoute(
                    name: 'room-device',
                    path: ':roomId',
                    builder: (context, state) => RoomDeviceScreen(
                      roomId: state.pathParameters['roomId']!,
                    ),
                    routes: [
                      GoRoute(
                        name: 'room-device-detail',
                        path: 'devices/:deviceId',
                        builder: (context, state) => DeviceDetailScreen(
                          deviceId: state.pathParameters['deviceId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'ai-assistant',
                path: '/ai-assistant',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AiAssistantScreen()),
              ),
              GoRoute(
                name: 'automation',
                path: '/automation',
                builder: (context, state) => const AutomationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'energy',
                path: '/energy',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: EnergyScreen()),
              ),
              GoRoute(
                name: 'camera',
                path: '/camera',
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'profile',
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    name: 'settings',
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    name: 'notifications',
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnboardingRoute = location == '/onboarding';
      final isSplashRoute = location == '/splash';
      final authRoutes = {'/login', '/register'};
      final isAuthRoute = authRoutes.contains(location);

      if (authState.status == AuthStatus.checking) {
        return isSplashRoute ? null : '/splash';
      }
      if (!onboardingCompleted) {
        return isOnboardingRoute ? null : '/onboarding';
      }
      if (isSplashRoute || isOnboardingRoute) {
        return authState.isAuthenticated ? '/home' : '/login';
      }
      if (!authState.isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (authState.isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
  );
});
