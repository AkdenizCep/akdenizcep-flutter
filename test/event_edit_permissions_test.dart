import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/community/models/club.dart';
import 'package:akdenizcep/features/community/pages/event_detail_page.dart';
import 'package:akdenizcep/features/community/providers/community_provider.dart';
import 'package:akdenizcep/features/student_events/pages/create_event_page.dart';
import 'package:akdenizcep/features/student_events/pages/student_event_detail_page.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/providers/event_feed_provider.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('kişisel etkinliğin yazarı düzenleme seçeneğini görür', (
    tester,
  ) async {
    const eventRef = EventRef.student('event-1');
    final event = FeedEvent(
      id: eventRef.eventId,
      source: EventSource.student,
      title: 'Kampüs Buluşması',
      date: DateTime(2026, 10, 10, 18),
      location: 'Olbia A Salonu',
      description: 'Etkinlik açıklaması',
      authorUid: 'owner-1',
      createdAt: DateTime(2026, 9),
    );
    final user = AppUser(
      id: 'owner-1',
      name: 'Etkinlik Sahibi',
      email: 'owner@ogr.akdeniz.edu.tr',
      studentId: '202600001',
      followedClubs: const [],
      createdAt: DateTime(2026, 9),
    );

    final container = ProviderContainer(
      overrides: [
        eventDetailProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(event)),
        eventCommentsProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(const [])),
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: StudentEventDetailPage(eventId: 'event-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Etkinliği Düzenle'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('topluluk yöneticisi etkinliği düzenleme seçeneğini görür', (
    tester,
  ) async {
    const eventRef = EventRef.club(clubId: 'club-1', eventId: 'event-2');
    final event = FeedEvent(
      id: eventRef.eventId,
      source: EventSource.club,
      clubId: eventRef.clubId,
      title: 'Topluluk Etkinliği',
      date: DateTime(2026, 10, 11, 19),
      location: 'Yakut Çarşı',
      description: 'Topluluk etkinliği açıklaması',
      createdAt: DateTime(2026, 9),
    );
    final club = Club(
      id: 'club-1',
      name: 'Yazılım Topluluğu',
      logoUrl: '',
      category: 'Teknoloji',
      followerCount: 10,
      adminUid: 'president-1',
      adminUids: const ['manager-1'],
      createdAt: DateTime(2026, 9),
    );
    final manager = AppUser(
      id: 'manager-1',
      name: 'Topluluk Yöneticisi',
      email: 'manager@ogr.akdeniz.edu.tr',
      studentId: '202600002',
      followedClubs: const [],
      createdAt: DateTime(2026, 9),
    );
    final container = ProviderContainer(
      overrides: [
        eventDetailProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(event)),
        eventCommentsProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(const [])),
        clubDetailProvider('club-1').overrideWith((ref) => Stream.value(club)),
        currentUserProvider.overrideWith((ref) => Stream.value(manager)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EventDetailPage(clubId: 'club-1', eventId: 'event-2'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Etkinliği Düzenle'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('kişisel etkinlik düzenleme formu mevcut verilerle açılır', (
    tester,
  ) async {
    const eventRef = EventRef.student('event-1');
    final event = FeedEvent(
      id: eventRef.eventId,
      source: EventSource.student,
      title: 'Kampüs Buluşması',
      date: DateTime(2026, 10, 10, 18, 30),
      location: 'Olbia A Salonu',
      locationLatitude: 36.8947,
      locationLongitude: 30.6512,
      description: 'Mevcut açıklama',
      category: 'technology',
      authorUid: 'owner-1',
      capacity: 45,
      createdAt: DateTime(2026, 9),
    );
    final user = AppUser(
      id: 'owner-1',
      name: 'Etkinlik Sahibi',
      email: 'owner@ogr.akdeniz.edu.tr',
      studentId: '202600001',
      followedClubs: const [],
      createdAt: DateTime(2026, 9),
    );
    final container = ProviderContainer(
      overrides: [
        eventDetailProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(event)),
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: EditEventPage(eventRef: eventRef)),
      ),
    );
    await tester.pump();

    expect(find.text('Etkinliği Düzenle'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kampüs Buluşması'), findsOneWidget);
    expect(find.text('Olbia A Salonu'), findsOneWidget);
  });
}
