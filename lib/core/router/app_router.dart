import 'package:go_router/go_router.dart';

import '../../features/map_display/presentation/screens/home_screen.dart';
import '../../features/map_display/presentation/screens/route_preview_screen.dart';
import '../../features/map_display/presentation/screens/navigation_screen.dart';
import '../../features/run_history/presentation/screens/run_history_screen.dart';
import '../../features/run_history/presentation/screens/run_detail_screen.dart';

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
    GoRoute(
      path: '/history',
      builder: (context, state) => const RunHistoryScreen(),
    ),
    GoRoute(
      path: '/history/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return RunDetailScreen(runId: id);
      },
    ),
  ],
);
