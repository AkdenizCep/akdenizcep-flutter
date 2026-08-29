import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_found_item.dart';

class LostFoundService {
  final _db = FirebaseFirestore.instance;

  Stream<List<LostFoundItem>> getItems() {
    return _db
        .collection('lost_found_items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LostFoundItem.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> createItem({
    required String authorUid,
    required String authorName,
    required String type,
    required String title,
    required String description,
    required String category,
    required String location,
    String imageUrl = '',
    String contactPhone = '',
  }) async {
    try {
      await _db.collection('lost_found_items').add({
        'authorUid': authorUid,
        'authorName': authorName,
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'location': location,
        'contactPhone': contactPhone,
        'isResolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('İlan oluşturulamadı: ${e.message}');
    }
  }

  Future<void> setResolved({
    required String itemId,
    required String authorUid,
    required bool resolved,
  }) async {
    try {
      final doc = await _db.collection('lost_found_items').doc(itemId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu ilanı düzenleme yetkiniz yok.');
      }
      await _db.collection('lost_found_items').doc(itemId).update({
        'isResolved': resolved,
      });
    } on FirebaseException catch (e) {
      throw Exception('İlan güncellenemedi: ${e.message}');
    }
  }

  Future<void> deleteItem({
    required String itemId,
    required String authorUid,
  }) async {
    try {
      final doc = await _db.collection('lost_found_items').doc(itemId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu ilanı silme yetkiniz yok.');
      }
      await _db.collection('lost_found_items').doc(itemId).delete();
    } on FirebaseException catch (e) {
      throw Exception('İlan silinemedi: ${e.message}');
    }
  }
}
