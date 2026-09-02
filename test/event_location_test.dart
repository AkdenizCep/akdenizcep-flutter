import 'package:akdenizcep/features/community/models/club_event.dart';
import 'package:akdenizcep/features/student_events/models/student_event.dart';
import 'package:akdenizcep/shared/models/feed_event.dart';
import 'package:akdenizcep/shared/utils/event_map_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final eventDate = DateTime(2026, 9, 15, 18, 30);
  final createdAt = DateTime(2026, 9, 1, 12);

  group('event coordinates', () {
    test('FeedEvent keeps coordinates through JSON and copyWith', () {
      final event = FeedEvent.fromJson({
        'id': 'event-1',
        'source': 'club',
        'clubId': 'club-1',
        'title': 'Tanışma Etkinliği',
        'date': eventDate,
        'location': 'Mühendislik Fakültesi B Blok',
        'locationLatitude': 36.8947,
        'locationLongitude': 30.6512,
        'description': 'Açıklama',
        'createdAt': createdAt,
      });

      expect(event.locationLatitude, 36.8947);
      expect(event.locationLongitude, 30.6512);
      expect(event.hasCoordinates, true);
      expect(event.toJson()['locationLatitude'], 36.8947);
      expect(event.copyWith(title: 'Yeni başlık').locationLongitude, 30.6512);
    });

    test('legacy FeedEvent without coordinates remains supported', () {
      final event = FeedEvent.fromJson({
        'id': 'event-2',
        'title': 'Eski Etkinlik',
        'date': eventDate,
        'location': 'Olbia A Salonu',
        'description': '',
        'createdAt': createdAt,
      });

      expect(event.locationLatitude, null);
      expect(event.locationLongitude, null);
      expect(event.hasCoordinates, false);
    });

    test('coordinates keep an event mappable when its title is empty', () {
      final event = FeedEvent.fromJson({
        'id': 'event-3',
        'title': 'Kısmi Taşınmış Etkinlik',
        'date': eventDate,
        'location': '',
        'locationLatitude': 36.8947,
        'locationLongitude': 30.6512,
        'description': '',
        'createdAt': createdAt,
      });

      expect(event.hasMappableLocation, true);
    });

    test('StudentEvent and ClubEvent serialize selected coordinates', () {
      final studentEvent = StudentEvent(
        id: 'student-1',
        title: 'Öğrenci Etkinliği',
        authorUid: 'user-1',
        date: eventDate,
        location: 'Kütüphane Önü',
        locationLatitude: 36.893,
        locationLongitude: 30.649,
        description: '',
        createdAt: createdAt,
      );
      final clubEvent = ClubEvent(
        id: 'club-event-1',
        title: 'Kulüp Etkinliği',
        date: eventDate,
        imageUrl: '',
        location: 'Yakut Çarşısı',
        locationLatitude: 36.891,
        locationLongitude: 30.647,
        description: '',
        createdAt: createdAt,
      );

      expect(studentEvent.toJson()['locationLatitude'], 36.893);
      expect(studentEvent.copyWith(title: 'Yeni').locationLongitude, 30.649);
      expect(clubEvent.toJson()['locationLongitude'], 30.647);
      expect(clubEvent.copyWith(title: 'Yeni').locationLatitude, 36.891);
    });
  });

  group('EventMapLinks', () {
    test('Google Maps link targets coordinates', () {
      final uri = EventMapLinks.googleMaps(
        latitude: 36.8947,
        longitude: 30.6512,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '36.8947,30.6512');
    });

    test('Apple Maps link includes coordinates and location title', () {
      final uri = EventMapLinks.appleMaps(
        latitude: 36.8947,
        longitude: 30.6512,
        title: 'Mühendislik Fakültesi B Blok',
      );

      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['ll'], '36.8947,30.6512');
      expect(uri.queryParameters['q'], 'Mühendislik Fakültesi B Blok');
    });

    test('legacy search link uses the saved title and campus context', () {
      final uri = EventMapLinks.googleMapsSearch('Olbia A Salonu');

      expect(
        uri.queryParameters['query'],
        'Olbia A Salonu, Akdeniz Üniversitesi',
      );
    });
  });
}
