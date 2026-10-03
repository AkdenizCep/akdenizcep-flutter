import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'bus_stop_icon.dart';

/// SVG'nin `viewBox` kenari. Arka plan kutusu ve olcekleme bu degere gore.
const _viewBox = 100.0;

/// SVG'deki yuvarlak kutunun cizgi ortasi: x=8, y=8, 84x84, rx=22.
final _sign = RRect.fromRectAndRadius(
  const Rect.fromLTWH(8, 8, 84, 84),
  const Radius.circular(22),
);

/// Durak ikonunu harita isareti icin `size` mantiksal pikselde bitmap'e cevirir.
///
/// Harita isaretleri widget degil gorsel ister; bu yuzden [BusStopIcon]'un
/// ayni SVG'si burada PNG'ye cizilir.
Future<BitmapDescriptor> busStopPinBitmap({
  required Color color,
  required Color backing,
  required double size,
  required double pixelRatio,
  AssetBundle? bundle,
}) async {
  final png = await busStopPinPng(
    color: color,
    backing: backing,
    pixelSize: (size * pixelRatio).round(),
    bundle: bundle,
  );
  return BitmapDescriptor.bytes(png, width: size, height: size);
}

/// [busStopPinBitmap]'in PNG ureten kismi; `pixelSize` x `pixelSize` piksel.
///
/// SVG'nin zemini `currentColor`'in %12 tonudur, yani yari saydam. Harita
/// karolari uzerinde harf okunmaz hale gelmesin diye SVG'nin altina opak bir
/// [backing] kutusu cizilir; cerceve ve harf [color] ile cizilir. [backing]
/// icin temanin yuzey rengi uygundur: hat renkleri (rozetlerde oldugu gibi)
/// yuzeyle kontrast olusturacak sekilde secilmistir.
Future<Uint8List> busStopPinPng({
  required Color color,
  required Color backing,
  required int pixelSize,
  AssetBundle? bundle,
}) async {
  final svg = await (bundle ?? rootBundle).loadString(BusStopIcon.asset);
  final info = await vg.loadPicture(
    SvgStringLoader(svg, theme: SvgTheme(currentColor: color)),
    null,
  );

  try {
    final scale = pixelSize / _viewBox;
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(scale)
      ..drawRRect(_sign, Paint()..color = backing)
      ..scale(_viewBox / info.size.width, _viewBox / info.size.height)
      ..drawPicture(info.picture);

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelSize, pixelSize);
    picture.dispose();

    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  } finally {
    info.picture.dispose();
  }
}
