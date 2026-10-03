import 'package:akdenizcep/features/ring/pages/components/stops_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'support/ring_fixtures.dart';

/// Haritada pine basinca ustunde durak adi baloncugu acilir. Baloncuga
/// dokunmak durak yapragini (siradaki kalkislar) acar; pine dokunmak ise
/// yalnizca duragi secer.
void main() {
  final testStop = stop(
    'durak_1',
    name: 'AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE',
    servedBy: [service('AÜ102'), service('AÜ103', isReturn: true)],
  );

  test('baloncuga dokunmak onInfoTap\'i, pine dokunmak onTap\'i cagirir', () {
    var tapped = 0;
    var infoTapped = 0;

    final marker = stopMarker(
      stop: testStop,
      icon: BitmapDescriptor.defaultMarker,
      onTap: () => tapped++,
      onInfoTap: () => infoTapped++,
    );

    marker.infoWindow.onTap!();
    expect(infoTapped, 1);
    expect(tapped, 0);

    marker.onTap!();
    expect(tapped, 1);
    expect(infoTapped, 1);
  });

  test('onInfoTap verilmezse baloncuk onTap\'e duser', () {
    var tapped = 0;

    final marker = stopMarker(
      stop: testStop,
      icon: BitmapDescriptor.defaultMarker,
      onTap: () => tapped++,
    );

    marker.infoWindow.onTap!();
    expect(tapped, 1);
  });

  test('capa varsayilan olarak alttadir ve degistirilebilir', () {
    final pin = stopMarker(
      stop: testStop,
      icon: BitmapDescriptor.defaultMarker,
      onTap: () {},
    );
    final sign = stopMarker(
      stop: testStop,
      icon: BitmapDescriptor.defaultMarker,
      onTap: () {},
      anchor: const Offset(0.5, 0.5),
    );

    expect(pin.anchor, const Offset(0.5, 1));
    expect(sign.anchor, const Offset(0.5, 0.5));
  });

  test('baloncuk durak adini ve gecen hatlari tasir', () {
    final marker = stopMarker(
      stop: testStop,
      icon: BitmapDescriptor.defaultMarker,
      onTap: () {},
    );

    expect(marker.markerId, MarkerId(testStop.id));
    expect(marker.infoWindow.title, testStop.name);
    expect(marker.infoWindow.snippet, 'AÜ102 · AÜ103');
    expect(
      marker.position,
      LatLng(testStop.lat, testStop.lng),
    );
  });
}
