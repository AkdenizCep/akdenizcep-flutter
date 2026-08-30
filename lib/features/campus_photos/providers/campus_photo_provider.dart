import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/campus_photo.dart';
import '../models/photo_comment.dart';
import '../services/campus_photo_service.dart';

final campusPhotoServiceProvider = Provider((_) => CampusPhotoService());

final campusPhotosProvider = StreamProvider<List<CampusPhoto>>((ref) {
  return ref.watch(campusPhotoServiceProvider).getPhotos();
});

final photoCommentsProvider = StreamProvider.family<List<PhotoComment>, String>((
  ref,
  photoId,
) {
  return ref.watch(campusPhotoServiceProvider).getComments(photoId);
});

/// Firestore yazımı tamamlanana kadar kalp ikonunun anında tepki vermesini
/// sağlayan geçici beğeni durumu. Anahtar: fotoğraf id'si.
class PhotoLikeNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  bool isLiked(CampusPhoto photo, String? uid) =>
      state[photo.id] ?? photo.likedByUser(uid);

  /// Ekranda gösterilecek beğeni sayısı — bekleyen değişiklik varsa ±1.
  int likeCount(CampusPhoto photo, String? uid) {
    final pending = state[photo.id];
    if (pending == null) return photo.likedBy.length;

    final actual = photo.likedByUser(uid);
    if (pending == actual) return photo.likedBy.length;
    return (photo.likedBy.length + (pending ? 1 : -1)).clamp(0, 1 << 30);
  }

  Future<void> toggle({required CampusPhoto photo, required String uid}) async {
    final next = !isLiked(photo, uid);
    state = {...state, photo.id: next};

    try {
      await ref
          .read(campusPhotoServiceProvider)
          .setLiked(photoId: photo.id, uid: uid, like: next);
    } finally {
      state = {...state}..remove(photo.id);
    }
  }
}

final photoLikeProvider = NotifierProvider<PhotoLikeNotifier, Map<String, bool>>(
  PhotoLikeNotifier.new,
);
