import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/board_item.dart';

class BoardService {
  final _db = FirebaseFirestore.instance;

  Stream<List<BoardItem>> getItems() {
    return _db
        .collection('board')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BoardItem.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> createItem({
    required String authorUid,
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      await _db.collection('board').add({
        'authorUid': authorUid,
        'title': title,
        'content': content,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Ilan olusturulamadi: ${e.message}');
    }
  }

  Future<void> deleteItem({
    required String itemId,
    required String authorUid,
  }) async {
    try {
      final doc = await _db.collection('board').doc(itemId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu ilani silme yetkiniz yok.');
      }
      await _db.collection('board').doc(itemId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Ilan silinemedi: ${e.message}');
    }
  }
}
