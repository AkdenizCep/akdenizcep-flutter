import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/services/cloudinary_service.dart';

typedef PhotoUploadFn =
    Future<String> Function({
      required Uint8List bytes,
      required String folder,
      String filename,
    });

typedef PhotoUpdateFn = Future<void> Function(String uid, String? photoUrl);

class ProfilePhotoService {
  ProfilePhotoService({
    CloudinaryService? cloudinaryService,
    FirebaseFirestore? firestore,
    PhotoUploadFn? uploadBytesFn,
    PhotoUpdateFn? updatePhotoUrlFn,
  }) : _uploadBytes =
           uploadBytesFn ??
           (cloudinaryService ?? CloudinaryService()).uploadBytes,
       _updatePhotoUrl =
           updatePhotoUrlFn ??
           ((uid, photoUrl) => (firestore ?? FirebaseFirestore.instance)
               .collection('users')
               .doc(uid)
               .update({
                 'photoUrl': photoUrl == null || photoUrl.isEmpty
                     ? FieldValue.delete()
                     : photoUrl,
               }));

  final PhotoUploadFn _uploadBytes;
  final PhotoUpdateFn _updatePhotoUrl;

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List jpegBytes,
  }) async {
    try {
      final url = await _uploadBytes(
        bytes: jpegBytes,
        folder: 'profile-photos/$uid',
        filename: 'avatar.jpg',
      );

      await _updatePhotoUrl(uid, url);
      return url;
    } catch (error, stackTrace) {
      debugPrint('Profil fotoğrafı yükleme hatası ($uid): $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> removeProfilePhoto({required String uid}) async {
    try {
      await _updatePhotoUrl(uid, null);
    } catch (error, stackTrace) {
      debugPrint('Profil fotoğrafı kaldırma hatası ($uid): $error\n$stackTrace');
      rethrow;
    }
  }
}
