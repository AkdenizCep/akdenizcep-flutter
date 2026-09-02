import 'package:akdenizcep/shared/components/event_location_preview.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'önizleme koordinatı gösterir ve dokunmayı harita aksiyonuna iletir',
    (tester) async {
      var opened = false;
      final event = FeedEvent(
        id: 'event-1',
        source: EventSource.club,
        title: 'Etkinlik',
        date: DateTime(2026, 9, 10),
        location: 'Mühendislik Fakültesi',
        locationLatitude: 36.8947,
        locationLongitude: 30.6512,
        description: '',
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventLocationPreview(
              event: event,
              onTap: () => opened = true,
              mapBuilder: (context, latitude, longitude) =>
                  Center(child: Text('$latitude,$longitude')),
            ),
          ),
        ),
      );

      expect(find.text('36.8947,30.6512'), findsOneWidget);
      expect(tester.getSize(find.byType(EventLocationPreview)).height, 140);

      await tester.tap(find.bySemanticsLabel('Konumu haritada aç'));
      expect(opened, true);
    },
  );

  testWidgets('koordinatsız eski etkinlikte simge yedeğini gösterir', (
    tester,
  ) async {
    final event = FeedEvent(
      id: 'legacy',
      source: EventSource.student,
      title: 'Eski Etkinlik',
      date: DateTime(2026, 9, 10),
      location: 'Olbia A Salonu',
      description: '',
      createdAt: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventLocationPreview(event: event, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
  });
}
