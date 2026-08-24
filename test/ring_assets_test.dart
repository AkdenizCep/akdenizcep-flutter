import 'dart:ui' as ui;

import 'package:akdenizcep/features/ring/services/route_shapes_service.dart';
import 'package:akdenizcep/features/ring/services/stops_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Duraklar ve hat cizgileri uygulamayla birlikte gelen asset'lerden okunuyor.
/// Bir asset `pubspec.yaml`'a kaydedilmezse ya da bozulursa uygulama calisma
/// aninda "Durak bilgisi alinamadi" der; bu test o hatayi derleme zamanina ceker.
///
/// Not: asset'ler derleme zamaninda paketlenir. Yeni bir asset ekledikten sonra
/// hot reload yetmez, uygulamanin yeniden baslatilmasi gerekir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('duraklar asseti kayitli ve okunabilir', () async {
    final bundle = await StopsService().load();

    expect(bundle.stops, hasLength(33));
    expect(bundle.stops.first.servedBy, isNotEmpty);
  });

  test('hat cizgileri asseti kayitli ve okunabilir', () async {
    final bundle = await RouteShapesService().load();

    expect(bundle.routes, hasLength(4));
    expect(bundle.lineNames, ['AÜ102', 'AÜ103']);
  });

  test('iki asset routeShapeId uzerinden birbirine baglanir', () async {
    final stops = await StopsService().load();
    final routes = await RouteShapesService().load();

    final known = routes.routes.map((r) => r.id).toSet();
    for (final stop in stops.stops) {
      for (final service in stop.servedBy) {
        expect(
          known,
          contains(service.routeShapeId),
          reason: '${stop.name} bilinmeyen guzergaha isaret ediyor',
        );
      }
    }
  });

  // Yol `stops_map.dart` icindeki `_pinAsset` ile ayni olmali.
  test('durak pini asseti kayitli ve gercekten saydam', () async {
    final data = await rootBundle.load('assets/images/ring_stop_pin.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    // Kaynak gorsel, saydamligi *boyanmis* dama deseniyle taklit eden bir
    // JPG'ydi; oldugu gibi kullanilsa her pinin etrafinda gri bir kare
    // cikardi. Kosenin alfasi 0 degilse o hata geri gelmis demektir.
    expect(pixels!.getUint8(3), 0, reason: 'sol ust kose saydam degil');

    // Pin'in ucu altta ortada; Maps'in varsayilan alt-orta capasi ancak
    // gorsel dikse dogru noktayi gosterir.
    expect(image.height, greaterThan(image.width));
  });
}
