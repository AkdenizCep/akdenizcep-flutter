import 'package:akdenizcep/features/student_events/services/student_events_service.dart';
import 'package:akdenizcep/features/lost_found/services/lost_found_service.dart';
import 'package:akdenizcep/features/campus_photos/services/campus_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('öğrenci etkinliği görünür ve moderasyonsuz oluşturulur', () {
    final data = studentEventCreatePayload(
      authorUid: 'student',
      authorName: 'Öğrenci',
      title: 'Etkinlik',
      date: DateTime.utc(2026, 9, 22),
      location: 'Kampüs',
      locationLatitude: 36.0,
      locationLongitude: 30.0,
      description: 'Açıklama',
    );
    expect(data['moderationStatus'], 'visible');
    expect(data['moderatedAt'], isNull);
    expect(data['moderatedBy'], isNull);
    expect(data['authorUid'], 'student');
  });

  test('kayıp eşya ilanı görünür ve moderasyonsuz oluşturulur', () {
    final data = lostFoundCreatePayload(
      authorUid: 'student',
      authorName: 'Öğrenci',
      type: 'lost',
      title: 'Anahtar',
      description: 'Açıklama',
      category: 'Diğer',
      location: 'Kampüs',
    );
    expect(data['moderationStatus'], 'visible');
    expect(data['moderatedAt'], isNull);
    expect(data['moderatedBy'], isNull);
    expect(data['authorUid'], 'student');
  });

  test('kampüs fotoğrafı görünür ve moderasyonsuz oluşturulur', () {
    final data = campusPhotoCreatePayload(
      authorUid: 'student',
      authorName: 'Öğrenci',
      imageUrl: 'https://example.com/a.jpg',
    );
    expect(data['moderationStatus'], 'visible');
    expect(data['moderatedAt'], isNull);
    expect(data['moderatedBy'], isNull);
    expect(data['authorUid'], 'student');
  });
}
