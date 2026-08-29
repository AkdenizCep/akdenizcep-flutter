import 'package:akdenizcep/features/lost_found/models/lost_found_category.dart';
import 'package:akdenizcep/features/lost_found/models/lost_found_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

LostFoundItem _item({
  String type = 'kayip',
  bool isResolved = false,
  String category = 'elektronik',
}) {
  return LostFoundItem(
    id: '1',
    authorUid: 'u1',
    authorName: 'Test Öğrenci',
    type: type,
    title: 'Siyah cüzdan',
    description: '',
    category: category,
    imageUrl: '',
    location: 'Kütüphane',
    contactPhone: '',
    isResolved: isResolved,
    createdAt: DateTime(2026, 8, 29),
  );
}

void main() {
  group('LostFoundItem', () {
    test('type "kayip" isLost true döner', () {
      expect(_item(type: 'kayip').isLost, isTrue);
    });

    test('type "bulundu" isLost false döner', () {
      expect(_item(type: 'bulundu').isLost, isFalse);
    });

    test('toJson beklenen alanları üretir', () {
      final item = _item(type: 'bulundu', isResolved: true);
      final json = item.toJson();

      expect(json['type'], 'bulundu');
      expect(json['isResolved'], isTrue);
      expect(json['category'], 'elektronik');
      expect(json['location'], 'Kütüphane');
    });

    test('fromJson Firestore Timestamp\'ini DateTime\'a çözer', () {
      final json = {
        ..._item(type: 'bulundu', isResolved: true).toJson(),
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 29, 10, 30)),
      };
      final restored = LostFoundItem.fromJson(json);

      expect(restored.type, 'bulundu');
      expect(restored.isResolved, isTrue);
      expect(restored.createdAt, DateTime(2026, 8, 29, 10, 30));
    });

    test('fromJson eksik alanlarda çökmez, güvenli varsayılana düşer', () {
      final item = LostFoundItem.fromJson(const {});

      expect(item.type, 'kayip');
      expect(item.isResolved, isFalse);
      expect(item.title, '');
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      final original = _item();
      final updated = original.copyWith(isResolved: true);

      expect(updated.isResolved, isTrue);
      expect(updated.title, original.title);
      expect(updated.authorUid, original.authorUid);
    });
  });

  group('LostFoundCategory.resolve', () {
    test('bilinen id doğru kategoriyi döner', () {
      expect(LostFoundCategory.resolve('anahtar'), LostFoundCategory.keys);
    });

    test('büyük/küçük harf ve boşluk normalize edilir', () {
      expect(LostFoundCategory.resolve('  ANAHTAR '), LostFoundCategory.keys);
    });

    test('bilinmeyen id "diğer"e düşer', () {
      expect(LostFoundCategory.resolve('uydurma-kategori'), LostFoundCategory.other);
    });

    test('null id "diğer"e düşer', () {
      expect(LostFoundCategory.resolve(null), LostFoundCategory.other);
    });

    test('katalogdaki her kategori benzersiz id taşır', () {
      final ids = LostFoundCategory.all.map((c) => c.id).toSet();
      expect(ids.length, LostFoundCategory.all.length);
    });
  });
}
