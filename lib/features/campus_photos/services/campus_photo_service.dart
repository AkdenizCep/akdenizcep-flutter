import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campus_photo.dart';
import '../models/photo_comment.dart';

class CampusPhotoService {
  final _db = FirebaseFirestore.instance;

  Stream<List<CampusPhoto>> getPhotos() {
    return _db
        .collection('campus_photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CampusPhoto.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> createPhoto({
    required String authorUid,
    required String authorName,
    required String imageUrl,
    String caption = '',
  }) async {
    try {
      await _db.collection('campus_photos').add({
        'authorUid': authorUid,
        'authorName': authorName,
        'imageUrl': imageUrl,
        'caption': caption,
        'likedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Fotoğraf paylaşılamadı: ${e.message}');
    }
  }

  /// [like] `true` ise beğeniyi ekler, `false` ise geri alır. Kural yalnızca
  /// çağıranın kendi uid'ini eklemesine/çıkarmasına izin verir.
  Future<void> setLiked({
    required String photoId,
    required String uid,
    required bool like,
  }) async {
    try {
      await _db.collection('campus_photos').doc(photoId).update({
        'likedBy': like
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
      });
    } on FirebaseException catch (e) {
      throw Exception('Beğeni kaydedilemedi: ${e.message}');
    }
  }

  Future<void> deletePhoto({
    required String photoId,
    required String authorUid,
  }) async {
    try {
      final doc = await _db.collection('campus_photos').doc(photoId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu fotoğrafı silme yetkiniz yok.');
      }
      await _db.collection('campus_photos').doc(photoId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Fotoğraf silinemedi: ${e.message}');
    }
  }

  Stream<List<PhotoComment>> getComments(String photoId) {
    return _db
        .collection('campus_photos')
        .doc(photoId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PhotoComment.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> addComment({
    required String photoId,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    try {
      await _db
          .collection('campus_photos')
          .doc(photoId)
          .collection('comments')
          .add({
            'authorUid': authorUid,
            'authorName': authorName,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      throw Exception('Yorum gönderilemedi: ${e.message}');
    }
  }

  Future<void> deleteComment({
    required String photoId,
    required String commentId,
    required String authorUid,
  }) async {
    try {
      final commentRef = _db
          .collection('campus_photos')
          .doc(photoId)
          .collection('comments')
          .doc(commentId);
      final doc = await commentRef.get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu yorumu silme yetkiniz yok.');
      }
      await commentRef.delete();
    } on FirebaseException catch (e) {
      throw Exception('Yorum silinemedi: ${e.message}');
    }
  }
}
