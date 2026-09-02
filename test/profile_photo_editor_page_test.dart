import 'dart:typed_data';

import 'package:akdenizcep/features/profile/pages/profile_photo_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('kırpma ekranı yönlendirme ve kaydetme kontrollerini gösterir', (
    tester,
  ) async {
    final source = img.Image(width: 20, height: 20)
      ..clear(img.ColorRgb8(19, 91, 236));

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePhotoEditorPage(
          imageBytes: Uint8List.fromList(img.encodeJpg(source)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Fotoğrafı Ayarla'), findsOneWidget);
    expect(
      find.text('Fotoğrafı sürükleyip yakınlaştırabilirsin.'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is FilledButton),
      findsOneWidget,
    );
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.byTooltip('İptal'), findsOneWidget);
  });
}
