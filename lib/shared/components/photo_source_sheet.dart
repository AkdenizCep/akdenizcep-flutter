import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Kamera/galeri seçim sayfası — görsel yükleyen tüm formlarda paylaşılır
/// (kayıp/buluntu ilanı, kampüs fotoğrafı paylaşımı).
///
/// Bulunan bir eşyanın ya da o anki bir karenin fotoğrafı genelde o an,
/// orada çekilir; kayıp bir eşyanınki ise çoğunlukla galeride hazır bir kare
/// olur. Bu yüzden ikisi de sunulur, tek bir kaynağa zorlanmaz.
Future<ImageSource?> choosePhotoSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Fotoğraf çek'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden seç'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}
