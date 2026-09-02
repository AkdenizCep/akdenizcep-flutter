import 'package:akdenizcep/shared/components/photo_source_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mevcut fotoğraf varsa kaldırma seçeneği gösterir', (
    tester,
  ) async {
    ProfilePhotoAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await chooseProfilePhotoAction(context, canRemove: true);
            },
            child: const Text('Aç'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Profil fotoğrafını kaldır'), findsOneWidget);

    await tester.tap(find.text('Profil fotoğrafını kaldır'));
    await tester.pumpAndSettle();
    expect(result, ProfilePhotoAction.remove);
  });

  testWidgets('fotoğraf yoksa kaldırma seçeneğini gizler', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                chooseProfilePhotoAction(context, canRemove: false),
            child: const Text('Aç'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Profil fotoğrafını kaldır'), findsNothing);
  });
}
