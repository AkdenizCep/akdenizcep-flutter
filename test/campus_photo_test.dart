import 'package:akdenizcep/features/campus_photos/models/campus_photo.dart';
import 'package:akdenizcep/features/campus_photos/models/photo_comment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

CampusPhoto _photo({List<String> likedBy = const []}) {
  return CampusPhoto(
    id: '1',
    authorUid: 'u1',
    authorName: 'Test Öğrenci',
    imageUrl: 'https://example.com/photo.jpg',
    caption: 'Kütüphane önünden',
    likedBy: likedBy,
    createdAt: DateTime(2026, 8, 29),
  );
}

void main() {
  group('CampusPhoto', () {
    test('likedByUser listedeki uid için true döner', () {
      expect(_photo(likedBy: ['u1', 'u2']).likedByUser('u2'), isTrue);
    });

    test('likedByUser listede olmayan uid için false döner', () {
      expect(_photo(likedBy: ['u1']).likedByUser('u2'), isFalse);
    });

    test('likedByUser null uid için false döner', () {
      expect(_photo(likedBy: ['u1']).likedByUser(null), isFalse);
    });

    test('toJson beklenen alanları üretir', () {
      final json = _photo(likedBy: ['u2']).toJson();

      expect(json['authorName'], 'Test Öğrenci');
      expect(json['caption'], 'Kütüphane önünden');
      expect(json['likedBy'], ['u2']);
    });

    test('fromJson Firestore Timestamp\'ini DateTime\'a çözer', () {
      final json = {
        ..._photo().toJson(),
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 29, 10, 30)),
      };
      final restored = CampusPhoto.fromJson(json);

      expect(restored.createdAt, DateTime(2026, 8, 29, 10, 30));
      expect(restored.caption, 'Kütüphane önünden');
    });

    test('fromJson eksik alanlarda çökmez, güvenli varsayılana düşer', () {
      final photo = CampusPhoto.fromJson(const {});

      expect(photo.caption, '');
      expect(photo.likedBy, isEmpty);
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      final original = _photo(likedBy: ['u1']);
      final updated = original.copyWith(likedBy: ['u1', 'u2']);

      expect(updated.likedBy, ['u1', 'u2']);
      expect(updated.caption, original.caption);
      expect(updated.authorUid, original.authorUid);
    });
  });

  group('PhotoComment', () {
    test('toJson/fromJson round trip', () {
      final comment = PhotoComment(
        id: 'c1',
        authorUid: 'u1',
        authorName: 'Test',
        text: 'Güzel kare',
        createdAt: DateTime(2026, 8, 29, 12),
      );
      final json = {
        ...comment.toJson(),
        'createdAt': Timestamp.fromDate(comment.createdAt),
      };
      final restored = PhotoComment.fromJson(json);

      expect(restored.text, 'Güzel kare');
      expect(restored.authorName, 'Test');
      expect(restored.createdAt, comment.createdAt);
    });
  });
}
