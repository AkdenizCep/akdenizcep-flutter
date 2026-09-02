import 'package:akdenizcep/features/auth/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTimestamp {
  final DateTime value;

  _FakeTimestamp(this.value);

  DateTime toDate() => value;
}

void main() {
  final createdAt = DateTime(2026, 9, 2);

  Map<String, dynamic> userJson({String? photoUrl}) {
    final json = <String, dynamic>{
      'id': 'student-1',
      'name': 'Akdeniz Öğrencisi',
      'email': 'student@ogr.akdeniz.edu.tr',
      'studentId': '20260001',
      'followedClubs': <String>[],
      'ratedMealIds': <String>[],
      'savedEventIds': <String>[],
      'createdAt': _FakeTimestamp(createdAt),
    };
    if (photoUrl != null) json['photoUrl'] = photoUrl;
    return json;
  }

  test('eski kullanıcı belgesinde profil fotoğrafını boş kabul eder', () {
    final user = AppUser.fromJson(userJson());

    expect(user.photoUrl, isEmpty);
  });

  test('profil fotoğrafını JSON ve copyWith boyunca korur', () {
    const url = 'https://res.cloudinary.com/example/avatar.jpg';
    final user = AppUser.fromJson(userJson(photoUrl: url));

    expect(user.photoUrl, url);
    expect(user.toJson()['photoUrl'], url);
    expect(user.copyWith(photoUrl: 'next.jpg').photoUrl, 'next.jpg');
  });
}
