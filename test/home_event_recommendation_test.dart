import 'package:akdenizcep/features/home/providers/home_provider.dart';
import 'package:akdenizcep/shared/models/club_option.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 1, 12);
  final clubs = [
    const ClubOption(
      id: 'followed-tech',
      name: 'Takip Edilen',
      category: 'Teknoloji',
    ),
    const ClubOption(
      id: 'peer-tech',
      name: 'Benzer Topluluk',
      category: ' teknoloji ',
    ),
    const ClubOption(id: 'music', name: 'Müzik Topluluğu', category: 'Müzik'),
  ];

  test(
    'takip edilen topluluk etkinliklerini önce, aynı kategoriyi sonra sıralar',
    () {
      final events = [
        _clubEvent('peer-soon', 'peer-tech', now.add(const Duration(hours: 1))),
        _clubEvent(
          'followed-later',
          'followed-tech',
          now.add(const Duration(days: 3)),
        ),
        _clubEvent('unrelated', 'music', now.add(const Duration(hours: 2))),
        _clubEvent(
          'followed-soon',
          'followed-tech',
          now.add(const Duration(days: 2)),
        ),
        _clubEvent(
          'past',
          'followed-tech',
          now.subtract(const Duration(minutes: 1)),
        ),
        _studentEvent('student', now.add(const Duration(hours: 3))),
      ];

      final result = selectRecommendedHomeEvents(
        events: events,
        clubs: clubs,
        followedClubIds: const ['followed-tech'],
        now: now,
      );

      expect(result.map((event) => event.id), [
        'followed-soon',
        'followed-later',
        'peer-soon',
      ]);
    },
  );

  test('hiç topluluk takip edilmiyorsa öneri üretmez', () {
    final result = selectRecommendedHomeEvents(
      events: [
        _clubEvent('peer-soon', 'peer-tech', now.add(const Duration(hours: 1))),
      ],
      clubs: clubs,
      followedClubIds: const [],
      now: now,
    );

    expect(result, isEmpty);
  });

  test('aynı etkinliği tekrarlamaz ve sonuç sayısını sınırlar', () {
    final first = _clubEvent(
      'followed-first',
      'followed-tech',
      now.add(const Duration(hours: 1)),
    );
    final result = selectRecommendedHomeEvents(
      events: [
        first,
        first,
        _clubEvent(
          'followed-second',
          'followed-tech',
          now.add(const Duration(hours: 2)),
        ),
        _clubEvent(
          'followed-third',
          'followed-tech',
          now.add(const Duration(hours: 3)),
        ),
      ],
      clubs: clubs,
      followedClubIds: const ['followed-tech'],
      now: now,
      limit: 2,
    );

    expect(result.map((event) => event.id), [
      'followed-first',
      'followed-second',
    ]);
  });
}

FeedEvent _clubEvent(String id, String clubId, DateTime date) => FeedEvent(
  id: id,
  source: EventSource.club,
  clubId: clubId,
  title: id,
  date: date,
  location: 'Kampüs',
  description: '',
  createdAt: date,
);

FeedEvent _studentEvent(String id, DateTime date) => FeedEvent(
  id: id,
  source: EventSource.student,
  title: id,
  date: date,
  location: 'Kampüs',
  description: '',
  createdAt: date,
);
