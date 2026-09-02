import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/home/pages/home_page.dart';
import 'package:akdenizcep/features/home/providers/home_provider.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('ana sayfa kişiselleştirilmiş topluluk etkinliğini gösterir', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Önerilen Teknoloji Buluşması'), findsOneWidget);
    expect(find.text('Yaklaşan etkinlik yok.'), findsNothing);
  });

  testWidgets('öneri kartı topluluk etkinliği detayını açar', (tester) async {
    await _pumpHome(tester);

    final title = find.text('Önerilen Teknoloji Buluşması');
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pumpAndSettle();

    expect(find.text('Topluluk etkinliği detayı'), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeContentPage()),
      GoRoute(
        path: '/club/:clubId/event/:eventId',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('Topluluk etkinliği detayı')),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(_user)),
        announcementsProvider.overrideWith((ref) => Stream.value(const [])),
        recommendedHomeEventsProvider.overrideWith(
          (ref) => AsyncData([_recommendedEvent]),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

final _user = AppUser(
  id: 'user-1',
  name: 'Test Öğrenci',
  email: 'test@ogr.akdeniz.edu.tr',
  studentId: '1',
  followedClubs: const ['club-1'],
  createdAt: DateTime(2026),
);

final _recommendedEvent = FeedEvent(
  id: 'event-1',
  source: EventSource.club,
  clubId: 'club-1',
  title: 'Önerilen Teknoloji Buluşması',
  date: DateTime(2026, 9, 10, 18),
  location: 'Kampüs',
  description: '',
  authorName: 'Teknoloji Topluluğu',
  createdAt: DateTime(2026, 8, 1),
);
