import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:akdenizcep/features/ring/pages/components/bus_stop_icon.dart';
import 'package:akdenizcep/features/ring/pages/components/bus_stop_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Haritadaki durak isareti: ayni SVG, bitmap'e cevrilmis. Harita karolari
/// uzerinde okunmasi icin zemin opak olmali.
void main() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  const lines = ['au102', 'au103'];

  final twoLineStop = stop(
    'durak_1',
    servedBy: [service('AÜ102'), service('AÜ103', isReturn: true)],
  );
  final only103Stop = stop(
    'durak_3',
    servedBy: [service('AÜ103', isReturn: true)],
  );

  group('busStopPinColor', () {
    test('aktif hat durak tarafindan kullaniliyorsa onun rengini alir', () {
      expect(
        busStopPinColor(colorScheme, lines, twoLineStop, activeLine: 'AÜ103'),
        colorScheme.onSurface,
      );
      expect(
        busStopPinColor(colorScheme, lines, twoLineStop, activeLine: 'AÜ102'),
        colorScheme.primary,
      );
    });

    test('aktif hat yoksa durak kendi hattina bakar', () {
      expect(
        busStopPinColor(colorScheme, lines, only103Stop),
        colorScheme.onSurface,
      );
      expect(
        busStopPinColor(colorScheme, lines, twoLineStop),
        colorScheme.primary,
      );
    });

    test('aktif hat duraktan gecmiyorsa durak kendi hattina bakar', () {
      expect(
        busStopPinColor(colorScheme, lines, only103Stop, activeLine: 'AÜ102'),
        colorScheme.onSurface,
      );
    });
  });

  group('busStopPinPng', () {
    Future<ui.Image> decode(Uint8List bytes) async {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    }

    Future<Color> pixelAt(ui.Image image, int x, int y) async {
      final data = (await image.toByteData())!;
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        data.getUint8(offset + 3),
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      );
    }

    testWidgets('PNG uretir; cerceve hat renginde, zemin opak', (tester) async {
      const color = Color(0xFFC62828);
      const backing = Color(0xFFFFFFFF);

      await tester.runAsync(() async {
        final png = await busStopPinPng(
          color: color,
          backing: backing,
          pixelSize: 200,
        );

        // PNG imzasi.
        expect(png.take(4).toList(), [0x89, 0x50, 0x4E, 0x47]);

        final image = await decode(png);
        expect(image.width, 200);
        expect(image.height, 200);

        // Sol cerceve seridinin ortasi (viewBox x=8 -> 16 px, y=50 -> 100 px).
        expect(await pixelAt(image, 16, 100), color);

        // Cerceve ile harf arasindaki zemin: opak ve hat renginin acik tonu
        // (beyaz zeminin ustune %12) — harita karosu gorunmez.
        final fill = await pixelAt(image, 40, 100);
        expect(fill.a, 1.0);
        expect(fill, isNot(color));
        expect(fill, isNot(backing));

        // Kose: SVG'nin disinda kalan sag ust piksel saydam.
        expect((await pixelAt(image, 199, 0)).a, 0.0);
      });
    });
  });
}
