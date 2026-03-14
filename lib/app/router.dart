import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/board/pages/board_page.dart';
import '../features/cafeteria/pages/cafeteria_page.dart';
import '../features/community/pages/club_detail_page.dart';
import '../features/community/pages/community_page.dart';
import '../features/community/pages/event_detail_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/map/pages/map_page.dart';
import '../features/ring/pages/ring_page.dart';
import '../features/student_events/pages/create_event_page.dart';
import '../features/student_events/pages/student_event_detail_page.dart';
import '../features/student_events/pages/student_events_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeContentPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityPage(),
                routes: [
                  GoRoute(
                    path: ':clubId',
                    builder: (context, state) => ClubDetailPage(
                      clubId: state.pathParameters['clubId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'event/:eventId',
                        builder: (context, state) => EventDetailPage(
                          clubId: state.pathParameters['clubId']!,
                          eventId: state.pathParameters['eventId']!,
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
                path: '/student-events',
                builder: (context, state) => const StudentEventsPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateEventPage(),
                  ),
                  GoRoute(
                    path: ':eventId',
                    builder: (context, state) => StudentEventDetailPage(
                      eventId: state.pathParameters['eventId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cafeteria',
                builder: (context, state) => const CafeteriaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const _MorePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ring',
        builder: (context, state) => const RingPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/board',
        builder: (context, state) => const BoardPage(),
      ),
    ],
  );
});

class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daha Fazla')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Ring Saatleri'),
            onTap: () => context.go('/ring'),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Kampus Haritasi'),
            onTap: () => context.go('/map'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Ilan Panosu'),
            onTap: () => context.go('/board'),
          ),
        ],
      ),
    );
  }
}
