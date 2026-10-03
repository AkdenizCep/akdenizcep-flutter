import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/home/models/quick_action.dart';
import 'package:akdenizcep/features/home/pages/home_page.dart';
import 'package:akdenizcep/features/home/providers/home_provider.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'home_quick_actions';

Finder _card(QuickAction action) =>
    find.byKey(ValueKey('quick-action-${action.name}'));

void main() {
  setUpAll(() => initializeDateFormatting('tr'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('kayit yokken varsayilan 6 kisayol gorunur', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Hızlı Erişim'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
    for (final action in kDefaultQuickActions) {
      expect(_card(action), findsOneWidget, reason: action.name);
    }
    expect(_card(QuickAction.campusMap), findsNothing);
  });

  testWidgets('kayitli secim ana sayfada gorunur', (tester) async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: [
        'campusMap',
        'lostFound',
        'campusPhotos',
        'emergencyContacts',
        'chatbot',
        'mediko',
      ],
    });
    await _pumpHome(tester);

    for (final action in const [
      QuickAction.campusMap,
      QuickAction.lostFound,
      QuickAction.campusPhotos,
      QuickAction.emergencyContacts,
      QuickAction.chatbot,
      QuickAction.mediko,
    ]) {
      expect(_card(action), findsOneWidget, reason: action.name);
    }
    expect(_card(QuickAction.obs), findsNothing);
  });

  testWidgets('Duzenle ile secim degisir, ana sayfa guncellenir ve saklanir', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Hızlı Erişimi Düzenle'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-obs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-campusMap')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Hızlı Erişimi Düzenle'), findsNothing);
    expect(_card(QuickAction.campusMap), findsOneWidget);
    expect(_card(QuickAction.obs), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_prefsKey), [
      'campusCard',
      'academicCalendar',
      'campusSecurity',
      'chatbot',
      'mediko',
      'campusMap',
    ]);
  });

  testWidgets('Duzenle sayfasini kaydetmeden kapatmak secimi degistirmez', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-obs')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 8));
    await tester.pumpAndSettle();

    expect(find.text('Hızlı Erişimi Düzenle'), findsNothing);
    expect(_card(QuickAction.obs), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_prefsKey), isNull);
  });

  testWidgets('Chatbot ve Mediko kartlari kendi rotalarini acar', (
    tester,
  ) async {
    final router = await _pumpHome(tester);

    await tester.tap(_card(QuickAction.chatbot));
    await tester.pumpAndSettle();
    expect(find.text('hedef:/chatbot'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();

    await tester.tap(_card(QuickAction.mediko));
    await tester.pumpAndSettle();
    expect(find.text('hedef:/mediko'), findsOneWidget);
  });

  testWidgets('Kampus sayfasi kisayolu ilgili kampus rotasini acar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: [
        'campusMap',
        'obs',
        'campusCard',
        'academicCalendar',
        'chatbot',
        'mediko',
      ],
    });
    await _pumpHome(tester);

    await tester.tap(_card(QuickAction.campusMap));
    await tester.pumpAndSettle();

    expect(find.text('hedef:/campus/map'), findsOneWidget);
  });
}

Future<GoRouter> _pumpHome(WidgetTester tester) async {
  // Genis ekran: test fontu (Ahem) harfleri gercekten ~2 kat genis cizdigi icin
  // ana sayfanin mevcut bolum basliklari telefon genisliginde tasiyor. Dar
  // ekran davranisi quick_actions_widgets_test.dart'ta ayrica kapsanir.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeContentPage()),
      for (final path in const ['/chatbot', '/mediko', '/campus/map'])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('hedef:$path')),
        ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(_user)),
        announcementsProvider.overrideWith((ref) => Stream.value(const [])),
        homeNowProvider.overrideWith((ref) => DateTime(2026, 10, 3, 9)),
        recommendedHomeEventsProvider.overrideWith(
          (ref) => const AsyncData(<FeedEvent>[]),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

final _user = AppUser(
  id: 'user-1',
  name: 'Test Öğrenci',
  email: 'test@ogr.akdeniz.edu.tr',
  studentId: '1',
  followedClubs: const [],
  createdAt: DateTime(2026),
);
