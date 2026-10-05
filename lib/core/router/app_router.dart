import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/designs/presentation/design_details_screen.dart';
import '../../features/designs/presentation/recommendations_screen.dart';
import '../../features/fabric/presentation/fabric_analysis_screen.dart';
import '../../features/fabric/presentation/upload_fabric_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/visualization/presentation/visualization_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const upload = '/upload';
  static const analysis = '/analysis';
  static const recommendations = '/recommendations';
  static String design(String id) => '/design/$id';
  static String visualize(String designId, {String? lookId}) =>
      '/visualize/$designId${lookId == null ? '' : '?look=$lookId'}';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(
              routes: [GoRoute(path: AppRoutes.favorites, builder: (_, _) => const FavoritesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: AppRoutes.upload, builder: (_, _) => const UploadFabricScreen()),
      GoRoute(path: AppRoutes.analysis, builder: (_, _) => const FabricAnalysisScreen()),
      GoRoute(path: AppRoutes.recommendations, builder: (_, _) => const RecommendationsScreen()),
      GoRoute(
        path: '/design/:id',
        builder: (_, state) => DesignDetailsScreen(designId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/visualize/:id',
        builder: (_, state) => VisualizationScreen(
          designId: state.pathParameters['id']!,
          lookId: state.uri.queryParameters['look'],
        ),
      ),
    ],
  );
});
