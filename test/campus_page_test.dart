import 'package:akdenizcep/app/theme.dart';
import 'package:akdenizcep/features/campus/pages/campus_page.dart';
import 'package:akdenizcep/features/campus/pages/emergency_contacts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Kampüs hizmetleri görünür ve hedefler tepki verir', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/campus',
      routes: [
        GoRoute(path: '/campus', builder: (_, _) => const CampusPage()),
        GoRoute(
          path: '/campus/map',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Harita hedefi'))),
        ),
        GoRoute(
          path: '/campus/emergency-contacts',
          builder: (_, _) => const EmergencyContactsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    for (final title in [
      'Kampüs Haritası',
      'Kayıp & Buluntu',
      'Kampüs Fotoğrafları',
      'Acil Numaralar',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Daha Fazla'), findsNothing);
    expect(find.text('Ayarlar'), findsNothing);
    expect(find.text('Geri Bildirim'), findsNothing);

    await tester.tap(find.text('Acil Numaralar'));
    await tester.pumpAndSettle();
    expect(find.text('Şimdi Ara'), findsOneWidget);

    router.go('/campus');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıp & Buluntu'));
    await tester.pump();
    expect(find.text('Kayıp & Buluntu sayfası hazırlanıyor.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Kampüs Haritası'));
    await tester.pumpAndSettle();
    expect(find.text('Harita hedefi'), findsOneWidget);
  });
}
