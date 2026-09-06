import 'dart:async';
import 'package:akdenizcep/app/router.dart';
import 'package:akdenizcep/app/theme.dart';
import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/auth/providers/auth_provider.dart' as auth;
import 'package:akdenizcep/features/profile/models/profile_club_summary.dart';
import 'package:akdenizcep/features/profile/models/profile_event_summary.dart';
import 'package:akdenizcep/features/profile/pages/components/my_events_section.dart';
import 'package:akdenizcep/features/profile/pages/profile_list_page.dart';
import 'package:akdenizcep/features/profile/pages/my_qr_page.dart';
import 'package:akdenizcep/features/profile/providers/profile_provider.dart';
import 'package:akdenizcep/features/profile/providers/profile_settings_provider.dart';
import 'package:akdenizcep/features/profile/services/profile_service.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/providers/event_feed_provider.dart';
import 'package:akdenizcep/shared/providers/theme_provider.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:akdenizcep/shared/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthUser implements User {
  @override
  bool get emailVerified => true;
  @override
  String get uid => 'u';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserService implements UserService {
  int resets = 0;
  int signOuts = 0;
  String? resetEmail;
  Completer<void>? pendingReset;
  bool fail = false;
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resets++;
    resetEmail = email;
    if (fail) throw Exception('Bağlantı kurulamadı');
    if (pendingReset != null) await pendingReset!.future;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (fail) throw Exception('Çıkış başarısız');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileService implements ProfileService {
  String? feedback;
  bool fail = false;
  @override
  Future<void> sendFeedback({
    required String uid,
    required String authorName,
    required String email,
    required String message,
  }) async {
    if (fail) throw Exception('Gönderilemedi');
    feedback = message;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _user = AppUser(
  id: 'u',
  name: 'Deniz Aydın',
  email: 'deniz@ogr.akdeniz.edu.tr',
  studentId: '123456',
  followedClubs: ['c'],
  createdAt: DateTime(2026),
);
final _clubs = List.generate(
  6,
  (i) => ProfileClubSummary(
    id: 'c$i',
    name: 'Topluluk $i',
    logoUrl: '',
    category: 'Sanat',
  ),
);
final _created = List.generate(
  4,
  (i) => ProfileEventSummary(
    id: 'e$i',
    title: 'Oluşturulan $i',
    date: DateTime(2026, 10, 12 + i, 17),
    location: 'Kampüs',
  ),
);
final _feed = [
  FeedEvent(
    id: 'student',
    source: EventSource.student,
    title: 'Katılınan öğrenci etkinliği',
    date: DateTime(2026, 10, 21),
    location: 'Olbia',
    description: '',
    createdAt: DateTime(2026),
    attendeeIds: ['u'],
  ),
  FeedEvent(
    id: 'club',
    source: EventSource.club,
    clubId: 'c',
    title: 'Katılınan topluluk etkinliği',
    date: DateTime(2026, 10, 25),
    location: 'Kampüs',
    description: '',
    createdAt: DateTime(2026),
    attendeeIds: ['u'],
  ),
  FeedEvent(
    id: 'other',
    source: EventSource.student,
    title: 'Başkasının etkinliği',
    date: DateTime(2026, 10, 27),
    location: 'Kampüs',
    description: '',
    createdAt: DateTime(2026),
    attendeeIds: ['other'],
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String route = '/profile',
  _UserService? users,
  _ProfileService? profiles,
  Size size = const Size(390, 1000),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      auth.authStateProvider.overrideWith((ref) => Stream.value(_AuthUser())),
      currentUserProvider.overrideWith((ref) => Stream.value(_user)),
      followedClubsProvider.overrideWith((ref) => Stream.value(_clubs)),
      myEventsProvider.overrideWith((ref) => Stream.value(_created)),
      eventFeedProvider.overrideWith((ref) => Stream.value(_feed)),
      userServiceProvider.overrideWithValue(users ?? _UserService()),
      profileServiceProvider.overrideWithValue(profiles ?? _ProfileService()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(auth.authStateProvider.future);
  await container.read(currentUserProvider.future);
  final router = container.read(routerProvider);
  router.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() => initializeDateFormatting('tr'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'profile previews, full lists, QR and settings use the real app routes without navbar',
    (tester) async {
      final container = await _pump(tester);
      final router = container.read(routerProvider);
      expect(find.text('Topluluk 4'), findsNothing);
      expect(find.text('Oluşturulan 2'), findsNothing);
      expect(find.text('Başkasının etkinliği'), findsNothing);
      expect(find.text('Yemekhane Puanların'), findsNothing);
      expect(find.text(_user.email), findsNothing);
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .bottomNavigationBar,
        isNull,
      );
      await tester.tap(find.text('Tümünü gör').first);
      await tester.pumpAndSettle();
      expect(find.text('Topluluk 5'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tümünü gör').last);
      await tester.tap(find.text('Tümünü gör').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileListPage), findsOneWidget);
      expect(find.text('Oluşturulan 3'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('QR kodum'));
      await tester.tap(find.text('QR kodum'));
      await tester.pumpAndSettle();
      expect(find.byType(MyQrPage), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hesap bilgileri'));
      await tester.pumpAndSettle();
      expect(find.text(_user.email), findsOneWidget);
      expect(find.text(_user.studentId), findsOneWidget);
      expect(find.text('Üyelik'), findsNothing);
    },
  );

  testWidgets(
    'joined previews link to the matching student and club detail routes',
    (tester) async {
      final container = await _pump(tester, route: '/profile/joined-events');
      final tiles = tester
          .widgetList<ProfileEventTile>(find.byType(ProfileEventTile))
          .toList();
      expect(tiles.map((t) => t.event.title), [
        'Katılınan topluluk etkinliği',
        'Katılınan öğrenci etkinliği',
      ]);
      expect(tiles.first.event.clubId, 'c');
      expect(container.read(joinedEventsProvider).requireValue.length, 2);
    },
  );

  testWidgets(
    'settings reset password, persist theme, validate feedback and confirm signout',
    (tester) async {
      final users = _UserService();
      final profiles = _ProfileService();
      final container = await _pump(
        tester,
        route: '/profile/settings',
        users: users,
        profiles: profiles,
      );
      await tester.tap(find.text('Şifre değiştir'));
      await tester.pumpAndSettle();
      expect(users.resetEmail, 'deniz@ogr.akdeniz.edu.tr');
      expect(find.textContaining('Şifre sıfırlama bağlantısı'), findsOneWidget);
      await tester.tap(find.text('Görünüm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siyah Tema').last);
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'app_theme_mode_preference',
        ),
        'dark',
      );
      await tester.tap(find.text('Görünüm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sistem teması').last);
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'app_theme_mode_preference',
        ),
        isNull,
      );
      await tester.tap(find.text('Geri bildirim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();
      expect(find.text('Lütfen bir mesaj yaz.'), findsOneWidget);
      expect(profiles.feedback, isNull);
      await tester.enterText(
        find.byType(TextFormField),
        '  Profil daha kullanışlı  ',
      );
      profiles.fail = true;
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gönderilemedi'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      profiles.fail = false;
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();
      expect(profiles.feedback, 'Profil daha kullanışlı');
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Çıkış yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(users.signOuts, 0);
      await tester.tap(find.text('Çıkış yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Çıkış yap'));
      await tester.pumpAndSettle();
      expect(users.signOuts, 1);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'profile and settings fit narrow screens with large text in ${dark ? 'dark' : 'light'} theme',
      (tester) async {
        final container = await _pump(
          tester,
          size: const Size(320, 720),
          textScale: 2,
          dark: dark,
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        container.read(routerProvider).go('/profile/settings');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'password action suppresses concurrent submissions and exposes failure',
    () async {
      final users = _UserService()..pendingReset = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          userServiceProvider.overrideWithValue(users),
          currentUserProvider.overrideWith((ref) => Stream.value(_user)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final provider = profileSettingsActionProvider(
        ProfileSettingsAction.password,
      );
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(provider.notifier);
      final pending = controller.submit();
      await controller.submit();
      expect(users.resets, 1);
      expect(container.read(provider).isLoading, isTrue);
      users.pendingReset!.complete();
      await pending;
      users.fail = true;
      await expectLater(controller.submit(), throwsException);
      expect(container.read(provider).hasError, isTrue);
    },
  );

  test(
    'joined events update when membership changes and do not leak after signout',
    () async {
      final feed = StreamController<List<FeedEvent>>();
      final users = StreamController<AppUser?>();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => users.stream),
          eventFeedProvider.overrideWith((ref) => feed.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await feed.close();
        await users.close();
      });
      final sub = container.listen(joinedEventsProvider, (_, _) {});
      addTearDown(sub.close);
      users.add(_user);
      await Future<void>.delayed(Duration.zero);
      feed.add(_feed);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(joinedEventsProvider).requireValue.map((e) => e.id),
        ['club', 'student'],
      );
      feed.add([_feed.first.copyWith(attendeeIds: [])]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(joinedEventsProvider).requireValue, isEmpty);
      feed.addError(Exception('offline'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(joinedEventsProvider).hasError, isTrue);
      users.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(joinedEventsProvider).requireValue, isEmpty);
    },
  );
}
