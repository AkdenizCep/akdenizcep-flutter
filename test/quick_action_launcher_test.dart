import 'package:akdenizcep/features/home/models/quick_action.dart';
import 'package:akdenizcep/features/home/pages/components/quick_action_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Uygulama ici sayfaya giden kisayollar. TL Yukleme (tarayici) ve Kampus
/// Guvenlik (arama) platform kanali gerektirdigi icin burada yoktur.
const _destinations = {
  QuickAction.obs: '/obs',
  QuickAction.academicCalendar: '/academic-calendar',
  QuickAction.chatbot: '/chatbot',
  QuickAction.mediko: '/mediko',
  QuickAction.campusMap: '/campus/map',
  QuickAction.lostFound: '/campus/lost-found',
  QuickAction.campusPhotos: '/campus/photos',
  QuickAction.emergencyContacts: '/campus/emergency-contacts',
};

void main() {
  for (final entry in _destinations.entries) {
    testWidgets('${entry.key.name} kisayolu ${entry.value} sayfasini acar', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => openQuickAction(context, entry.key),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
          for (final path in _destinations.values)
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text('hedef:$path')),
            ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('hedef:${entry.value}'), findsOneWidget);
    });
  }

  test('her kisayol ya uygulama ici hedefe ya da harici eyleme baglidir', () {
    const external = {QuickAction.campusCard, QuickAction.campusSecurity};

    expect(
      {..._destinations.keys, ...external},
      QuickAction.values.toSet(),
      reason: 'Katalogdaki her kisayol testte hesaba katilmali.',
    );
  });
}
