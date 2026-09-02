import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const maxProfilePhotoBytes = 1024 * 1024;
const profilePhotoDimension = 512;
const profilePhotoJpegQuality = 82;

Future<Uint8List> encodeProfilePhoto(Uint8List sourceBytes) {
  return compute(_encodeProfilePhoto, sourceBytes);
}

Uint8List _encodeProfilePhoto(Uint8List sourceBytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(sourceBytes);
  } on Object {
    throw const FormatException('Seçilen dosya geçerli bir görsel değil.');
  }
  if (decoded == null) {
    throw const FormatException('Seçilen dosya geçerli bir görsel değil.');
  }

  final squareSize = decoded.width < decoded.height
      ? decoded.width
      : decoded.height;
  final square = decoded.width == decoded.height
      ? decoded
      : img.copyCrop(
          decoded,
          x: (decoded.width - squareSize) ~/ 2,
          y: (decoded.height - squareSize) ~/ 2,
          width: squareSize,
          height: squareSize,
        );
  final resized = img.copyResize(
    square,
    width: profilePhotoDimension,
    height: profilePhotoDimension,
    interpolation: img.Interpolation.average,
  );
  final encoded = Uint8List.fromList(
    img.encodeJpg(resized, quality: profilePhotoJpegQuality),
  );

  if (encoded.length > maxProfilePhotoBytes) {
    throw const FormatException('Profil fotoğrafı yükleme sınırını aşıyor.');
  }
  return encoded;
}
