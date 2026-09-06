import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:akdenizcep/features/profile/pages/components/profile_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('header keeps account details private and opens personal QR', (
    tester,
  ) async {
    final user = AppUser(
      id: 'u',
      name: 'Deniz Aydın',
      email: 'deniz@ogr.akdeniz.edu.tr',
      studentId: '123456',
      followedClubs: [],
      createdAt: DateTime(2026),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ProfileInfoCard(
              user: user,
              photoBusy: false,
              onPhotoTap: () {},
            ),
          ),
        ),
        GoRoute(
          path: '/qr',
          builder: (_, _) => const Scaffold(body: Text('Kişisel QR ekranı')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text(user.email), findsNothing);
    expect(find.text(user.studentId), findsNothing);
    await tester.tap(find.text('QR kodum'));
    await tester.pumpAndSettle();
    expect(find.text('Kişisel QR ekranı'), findsOneWidget);
  });
}
