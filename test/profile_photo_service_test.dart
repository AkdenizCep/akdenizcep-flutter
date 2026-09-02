import 'dart:typed_data';

import 'package:akdenizcep/features/profile/services/profile_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profil fotoğrafını Cloudinaryye yükleyip Firestoreda günceller', () async {
    String? uploadedFolder;
    Uint8List? uploadedBytes;
    String? updatedUid;
    String? updatedUrl;

    final service = ProfilePhotoService(
      uploadBytesFn: ({required bytes, required folder, filename = 'upload.jpg'}) async {
        uploadedBytes = bytes;
        uploadedFolder = folder;
        return 'https://res.cloudinary.com/example/avatar.jpg';
      },
      updatePhotoUrlFn: (uid, photoUrl) async {
        updatedUid = uid;
        updatedUrl = photoUrl;
      },
    );

    final testBytes = Uint8List.fromList([0xff, 0xd8, 0xff]);
    final url = await service.uploadProfilePhoto(
      uid: 'user-123',
      jpegBytes: testBytes,
    );

    expect(url, 'https://res.cloudinary.com/example/avatar.jpg');
    expect(uploadedFolder, 'profile-photos/user-123');
    expect(uploadedBytes, testBytes);
    expect(updatedUid, 'user-123');
    expect(updatedUrl, 'https://res.cloudinary.com/example/avatar.jpg');
  });

  test('profil fotoğrafı kaldırma Firestore alanını temizler', () async {
    String? updatedUid;
    String? updatedUrl;

    final service = ProfilePhotoService(
      uploadBytesFn: ({required bytes, required folder, filename = 'upload.jpg'}) async {
        return '';
      },
      updatePhotoUrlFn: (uid, photoUrl) async {
        updatedUid = uid;
        updatedUrl = photoUrl;
      },
    );

    await service.removeProfilePhoto(uid: 'user-456');

    expect(updatedUid, 'user-456');
    expect(updatedUrl, isNull);
  });

  test('Cloudinary yükleme hatası durumunda Firestore güncellenmez ve hata fırlatılır', () async {
    var updateCalled = false;

    final service = ProfilePhotoService(
      uploadBytesFn: ({required bytes, required folder, filename = 'upload.jpg'}) async {
        throw Exception('Cloudinary bağlantı hatası');
      },
      updatePhotoUrlFn: (uid, photoUrl) async {
        updateCalled = true;
      },
    );

    expect(
      () => service.uploadProfilePhoto(
        uid: 'user-789',
        jpegBytes: Uint8List.fromList([0x01]),
      ),
      throwsException,
    );
    expect(updateCalled, isFalse);
  });
}
