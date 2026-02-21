import 'package:go_router/go_router.dart';

import '../../features/map_display/presentation/screens/home_screen.dart';
import '../../features/map_display/presentation/screens/route_preview_screen.dart';
import '../../features/map_display/presentation/screens/navigation_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/route-preview',
      builder: (context, state) => const RoutePreviewScreen(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationScreen(),
    ),
  ],
);
