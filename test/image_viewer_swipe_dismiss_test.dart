import 'package:akdenizcep/features/home/models/announcement.dart';
import 'package:akdenizcep/features/home/pages/announcement_image_viewer_page.dart';
import 'package:akdenizcep/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'normal ölçekte aşağı sürüklenen görsel görüntüleyiciyi kapatır',
    (tester) async {
      await _pumpOpenViewer(tester);

      await tester.drag(find.byType(InteractiveViewer), const Offset(0, 240));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AnnouncementImageViewerPage), findsNothing);
      expect(find.text('Görseli aç'), findsOneWidget);
    },
  );

  testWidgets('kısa aşağı sürükleme görseli yerine döndürür', (tester) async {
    await _pumpOpenViewer(tester);
    final hero = find.byType(Hero);
    final initialCenter = tester.getCenter(hero);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InteractiveViewer)),
    );

    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(tester.getCenter(hero).dy, greaterThan(initialCenter.dy + 40));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.getCenter(hero).dy, closeTo(initialCenter.dy, 1));
    expect(find.byType(AnnouncementImageViewerPage), findsOneWidget);
  });

  testWidgets('yakınlaştırılmış görsel aşağı sürüklenince açık kalır', (
    tester,
  ) async {
    await _pumpOpenViewer(tester);
    final interactiveViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    interactiveViewer.transformationController!.value = Matrix4.diagonal3Values(
      2,
      2,
      1,
    );
    await tester.pump();

    await tester.drag(find.byType(InteractiveViewer), const Offset(0, 240));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AnnouncementImageViewerPage), findsOneWidget);
  });
}

Future<void> _pumpOpenViewer(WidgetTester tester) async {
  final announcement = Announcement(
    id: 'announcement-1',
    imageUrl: 'https://example.com/announcement.jpg',
    title: 'Duyuru',
    context: 'Kampüs',
    createdAt: DateTime(2026, 9, 9),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        announcementsProvider.overrideWith(
          (ref) => Stream.value([announcement]),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnnouncementImageViewerPage(
                      announcementId: 'announcement-1',
                    ),
                  ),
                ),
                child: const Text('Görseli aç'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Görseli aç'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(AnnouncementImageViewerPage), findsOneWidget);
}
