import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akdenizcep/features/profile/pages/components/theme_selection_button.dart';
import 'package:akdenizcep/shared/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tema butonuna basıldığında seçenekler alt sayfası açılır ve seçim yapılabilir', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ThemeSelectionButton(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Başlangıçta buton görünmeli
    expect(find.byType(ThemeSelectionButton), findsOneWidget);
    expect(find.textContaining('Tema:'), findsOneWidget);

    // Butona dokun ve alt sayfayı aç
    await tester.tap(find.byType(ThemeSelectionButton));
    await tester.pumpAndSettle();

    // Başlık ve seçenekler görünmeli
    expect(find.text('Tema Seçimi'), findsOneWidget);
    expect(find.text('Beyaz Tema'), findsOneWidget);
    expect(find.text('Siyah Tema'), findsOneWidget);

    // Siyah Temayı seç
    await tester.tap(find.text('Siyah Tema'));
    await tester.pumpAndSettle();

    // Alt sayfa kapanmalı ve provider ThemeMode.dark olmalı
    expect(find.text('Tema Seçimi'), findsNothing);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(find.text('Tema: Siyah Tema'), findsOneWidget);

    // Tekrar açıp Beyaz Temayı seç
    await tester.tap(find.byType(ThemeSelectionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beyaz Tema'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(find.text('Tema: Beyaz Tema'), findsOneWidget);
  });
}
