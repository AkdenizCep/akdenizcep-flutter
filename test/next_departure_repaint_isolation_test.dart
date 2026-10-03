import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/pages/components/next_departure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yon degistirme animasyonlari (oklarin donmesi + adlarin yer degistirmesi)
/// performansi dusurmemeli. Olcu: animasyonun disinda kalan, kartla ayni
/// sayfadaki bir "gozlemci" cizici animasyon boyunca yeniden cizilmemeli.
///
/// Surekli animasyon calisan bir widget kendi `RepaintBoundary`'sinde degilse,
/// her karede bulundugu en yakin katmanin tamami (kart, golgesi, saat seritleri)
/// yeniden kaydedilir. Gozlemci bu durumda her karede boyanir.
void main() {
  final lines = [
    LineDepartures(
      lineCode: 'au102',
      departures: RingDepartures.from(
        weekdayTimes: const ['08:00', '09:00'],
        weekendTimes: const [],
        showWeekend: false,
        now: DateTime(2026, 7, 27, 7, 30),
      ),
    ),
  ];

  testWidgets('animasyon boyunca sayfanin geri kalani yeniden cizilmez', (
    tester,
  ) async {
    final paints = _Probe();
    final names = ValueNotifier(('Adli Tıp', 'Meltem Kapısı'));

    await tester.pumpWidget(
      MaterialApp(
        // Dokunus dalgasi (InkWell splash) de bir animasyondur ve her
        // dugmede vardir; olcumu yalniz bizim animasyonlarimiz belirlesin.
        theme: ThemeData(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        home: Scaffold(
          body: Column(
            children: [
              CustomPaint(painter: paints, size: const Size(10, 10)),
              ValueListenableBuilder<(String, String)>(
                valueListenable: names,
                builder: (context, value, _) => NextDepartureCard(
                  lines: lines,
                  originName: value.$1,
                  destinationName: value.$2,
                  fallbackTitle: 'Gidiş',
                  canSwitchDirection: true,
                  onSwitchDirection: () => names.value = (value.$2, value.$1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Değiştir'));
    // Tetikleyen kare: kart yeni ada gore yeniden kurulur, bir kez boyanir.
    await tester.pump();
    final afterTrigger = paints.count;

    // Animasyonun geri kalani (~520 ms): kare kare ilerle.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      paints.count,
      afterTrigger,
      reason: 'animasyon kareleri sayfanin geri kalanini yeniden cizdi',
    );
    // Animasyon gercekten calisti: adlar yer degistirdi.
    expect(
      tester.getTopLeft(find.text('Meltem Kapısı')).dx,
      lessThan(tester.getTopLeft(find.text('Adli Tıp')).dx),
    );
  });
}

class _Probe extends CustomPainter {
  int count = 0;

  @override
  void paint(Canvas canvas, Size size) => count++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
