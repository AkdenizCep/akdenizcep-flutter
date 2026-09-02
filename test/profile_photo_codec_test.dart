import 'dart:typed_data';

import 'package:akdenizcep/features/profile/services/profile_photo_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('kırpılmış görseli 512x512 JPEG olarak kodlar', () async {
    final source = img.Image(width: 900, height: 900)
      ..clear(img.ColorRgb8(19, 91, 236));
    final sourceBytes = Uint8List.fromList(img.encodePng(source));

    final result = await encodeProfilePhoto(sourceBytes);
    final decoded = img.decodeJpg(result);

    expect(result.take(3), [0xff, 0xd8, 0xff]);
    expect(decoded, isNotNull);
    expect(decoded!.width, 512);
    expect(decoded.height, 512);
    expect(result.length, lessThanOrEqualTo(maxProfilePhotoBytes));
  });

  test('bozuk görsel verisini reddeder', () async {
    expect(
      () => encodeProfilePhoto(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
