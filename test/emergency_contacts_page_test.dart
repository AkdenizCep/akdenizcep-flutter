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
      'GÜVENLİK İHBAR HATTI',
      '0242 310 22 22',
      'Yerleşke içinden dahili 112 veya 22 22',
      'Koruma ve Güvenlik Şube Müdürlüğü',
      'Güvenlik Amirliği',
      'Güvenlik Şefliği',
      'Güvenlik Trafik',
      '0 242 310 17 41',
      'Santrali Ara  •  0242 227 44 00',
      'Meltem Kapısı',
      '1664',
      'Toros Kapısı',
      '3379',
      'Uncalı Kapısı',
      '6921',
      'Teknokent Kapısı',
      '6013',
    ]) {
      expect(find.text(text), findsOneWidget);
    }

    expect(find.text('DAHİLİ'), findsNWidgets(4));
    expect(find.text('Şimdi Ara'), findsOneWidget);
    expect(find.textContaining('7/24'), findsNothing);
    expect(find.textContaining('Ara 112'), findsNothing);
    expect(find.textContaining('Resmî kaynak'), findsNothing);
    expect(find.textContaining('Nasıl aranır?'), findsOneWidget);
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

    expect(find.text('6013'), findsOneWidget);
  });
}
