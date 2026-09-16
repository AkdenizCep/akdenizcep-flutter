import 'package:akdenizcep/app/theme.dart';
import 'package:akdenizcep/features/campus/pages/emergency_contacts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('güvenlik iletişim bilgilerini eksiksiz gösterir', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const EmergencyContactsPage()),
    );
    await tester.pumpAndSettle();

    for (final text in [
      'Kampüs Güvenliği',
      'Güvenlik İhbar Hattı',
      '0 242 310 22 22',
      'Yerleşke içinden dahili 112 veya 22 22',
      'Koruma ve Güvenlik Şube Müdürlüğü',
      'Güvenlik Amirliği',
      'Güvenlik Şefliği',
      'Güvenlik Trafik',
      '0 242 310 17 41',
      '0 242 227 44 00',
      'Meltem Kapısı',
      'Doğu kapısı · Dahili 1664',
      'Toros Kapısı',
      'Güney kapısı · Dahili 3379',
      'Uncalı Kapısı',
      'Batı kapısı · Dahili 6921',
      'Teknokent Kapısı',
      'Kuzey kapısı · Dahili 6013',
    ]) {
      expect(find.text(text), findsOneWidget);
    }

    expect(find.textContaining('kapısı · Dahili'), findsNWidgets(4));
    expect(find.textContaining('Büro hattı'), findsNWidgets(4));
    expect(find.textContaining('7/24'), findsNothing);
    expect(find.textContaining('Ara 112'), findsNothing);
    expect(find.textContaining('Resmî kaynak'), findsNothing);
    expect(
      find.textContaining('Santrali ara, bağlantı kurulunca'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('küçük ekranda ve büyütülmüş yazıda taşmaz', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const EmergencyContactsPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kuzey kapısı · Dahili 6013'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
