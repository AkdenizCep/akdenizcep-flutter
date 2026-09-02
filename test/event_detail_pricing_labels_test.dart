import 'package:akdenizcep/shared/components/event_detail_view.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/providers/event_feed_provider.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('etkinlik detayı fiyat ve kayıt metinlerini göstermez', (
    tester,
  ) async {
    const eventRef = EventRef.student('event-1');
    final event = FeedEvent(
      id: eventRef.eventId,
      source: EventSource.student,
      title: 'Kampüs Etkinliği',
      date: DateTime(2026, 9, 10, 18),
      location: 'Olbia A Salonu',
      description: 'Etkinlik açıklaması',
      category: 'Sosyal',
      createdAt: DateTime(2026, 9),
    );

    final container = ProviderContainer(
      overrides: [
        eventDetailProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(event)),
        eventCommentsProvider(
          eventRef,
        ).overrideWith((ref) => Stream.value(const [])),
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: EventDetailView(eventRef: eventRef)),
      ),
    );
    await tester.pump();

    expect(find.text('ÜCRETSİZ'), findsNothing);
    expect(find.text('Ücretsiz'), findsNothing);
    expect(find.text('Kayıt gerekli'), findsNothing);
    expect(find.text('Katıl'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
  });
}
