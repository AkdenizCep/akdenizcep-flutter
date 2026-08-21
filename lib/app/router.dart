import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/pages/verify_email_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/board/pages/board_page.dart';
import '../features/cafeteria/pages/cafeteria_page.dart';
import '../features/community/pages/club_detail_page.dart';
import '../features/community/pages/club_settings_page.dart';
import '../features/community/pages/community_page.dart';
import '../features/community/pages/event_attendance_list_page.dart';
import '../features/community/pages/event_attendance_scan_page.dart';
import '../features/community/pages/event_detail_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/map/pages/map_page.dart';
import '../features/profile/pages/my_qr_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/ring/pages/ring_page.dart';
import '../features/ring/pages/ring_stops_page.dart';
import '../features/student_events/pages/create_event_page.dart';
import '../features/student_events/pages/student_event_detail_page.dart';
import '../features/student_events/pages/student_events_page.dart';

// Shell branch navigator keys — birden fazla branch aynı yolu paylaşmasın
final _shellHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellCafeteriaKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellCafeteria',
);
final _shellRingKey = GlobalKey<NavigatorState>(debugLabel: 'shellRing');
final _shellEventsKey = GlobalKey<NavigatorState>(debugLabel: 'shellEvents');
final _shellMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isVerifyRoute = state.matchedLocation == '/verify-email';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }
      if (!isEmailVerified) {
        return isVerifyRoute ? null : '/verify-email';
      }
      if (isAuthRoute || isVerifyRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      // Birden fazla sekmeden açılabilen detay sayfaları — kök navigator'a
      // eklenir ki geri tuşu, hangi sekmeden açıldığına bakmaksızın direkt
      // açılan sayfayı kapatıp kaldığımız yere dönsün.
      GoRoute(
        path: '/club/:clubId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ClubDetailPage(clubId: state.pathParameters['clubId']!),
        routes: [
          GoRoute(
            path: 'event/:eventId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => EventDetailPage(
              clubId: state.pathParameters['clubId']!,
              eventId: state.pathParameters['eventId']!,
            ),
            routes: [
              GoRoute(
                path: 'scan',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => EventAttendanceScanPage(
                  clubId: state.pathParameters['clubId']!,
                  eventId: state.pathParameters['eventId']!,
                ),
              ),
              GoRoute(
                path: 'attendance',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => EventAttendanceListPage(
                  clubId: state.pathParameters['clubId']!,
                  eventId: state.pathParameters['eventId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                ClubSettingsPage(clubId: state.pathParameters['clubId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/event/:eventId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            StudentEventDetailPage(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/board',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BoardPage(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyQrPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          // 0 — Ana Sayfa
          StatefulShellBranch(
            navigatorKey: _shellHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeContentPage(),
              ),
            ],
          ),
          // 1 — Yemekhane
          StatefulShellBranch(
            navigatorKey: _shellCafeteriaKey,
            routes: [
              GoRoute(
                path: '/cafeteria',
                builder: (context, state) => const CafeteriaPage(),
              ),
            ],
          ),
          // 2 — Ring
          StatefulShellBranch(
            navigatorKey: _shellRingKey,
            routes: [
              GoRoute(
                path: '/ring',
                builder: (context, state) => const RingPage(),
                routes: [
                  GoRoute(
                    path: 'stops',
                    builder: (context, state) => const RingStopsPage(),
                  ),
                ],
              ),
            ],
          ),
          // 3 — Etkinlikler
          StatefulShellBranch(
            navigatorKey: _shellEventsKey,
            routes: [
              GoRoute(
                path: '/student-events',
                builder: (context, state) => const StudentEventsPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateEventPage(),
                  ),
                ],
              ),
            ],
          ),
          // 4 — Harita
          StatefulShellBranch(
            navigatorKey: _shellMapKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
