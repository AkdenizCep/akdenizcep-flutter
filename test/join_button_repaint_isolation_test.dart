import 'dart:async';

import 'package:akdenizcep/shared/components/join_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Katil butonunun loading + tik animasyonu performansi dusurmemeli.
/// Olcu: butonla ayni sayfadaki, animasyonun disinda kalan bir "gozlemci"
/// cizici animasyon boyunca yeniden cizilmemeli.
///
/// Surekli donen bir spinner kendi `RepaintBoundary`'sinde degilse, her
/// karede bulundugu en yakin katmanin tamami yeniden kaydedilir.
void main() {
  /// Gercek ekranlarda katilim durumu provider'dan gelir; harness de ayni
  /// sekilde `onPressed` basarili olunca `joined`'i cevirir.
  Future<void> pumpButton(
    WidgetTester tester, {
    required _Probe probe,
    required ValueNotifier<bool> joined,
    required Future<void> Function() onPressed,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        // Dokunus dalgasi (InkWell splash) de bir animasyondur; olcumu
        // yalniz bizim animasyonlarimiz belirlesin.
        theme: ThemeData(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        home: Scaffold(
          // Gozlemcinin konumu butonun genisligine bagli olmamali; yoksa
          // olctugumuz sey boyama degil, yeniden yerlesim olur.
          body: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomPaint(painter: probe, size: const Size(10, 10)),
                ValueListenableBuilder<bool>(
                  valueListenable: joined,
                  builder: (context, value, _) => JoinButton(
                    joined: value,
                    enabled: true,
                    onPressed: onPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('loading spinner sayfanin geri kalanini yeniden cizmez', (
    tester,
  ) async {
    final probe = _Probe();
    final gate = Completer<void>();

    final joined = ValueNotifier(false);
    await pumpButton(
      tester,
      probe: probe,
      joined: joined,
      onPressed: () => gate.future,
    );
    await tester.pump();

    await tester.tap(find.text('Katıl'));
    // Tetikleyen kare: buton loading'e gecer, bir kez boyanir.
    await tester.pump();
    final afterTrigger = probe.count;

    // Spinner donuyor: 30 kare ilerle (~480 ms).
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final duringLoading = probe.count;

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Butce: spinner donerken ek boyama olmamali. Tek izin verilen boyama,
    // metinden spinner'a gecisin genisligi degistirdigi tek karedir.
    expect(
      duringLoading - afterTrigger,
      lessThanOrEqualTo(1),
      reason:
          'spinner kareleri sayfanin geri kalanini yeniden cizdi '
          '(${duringLoading - afterTrigger} fazla boyama)',
    );

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('tik gecisi sayfanin geri kalanini yeniden cizmez', (
    tester,
  ) async {
    final probe = _Probe();

    final joined = ValueNotifier(false);
    await pumpButton(
      tester,
      probe: probe,
      joined: joined,
      onPressed: () async => joined.value = true,
    );
    await tester.pump();

    await tester.tap(find.text('Katıl'));
    await tester.pump();
    final afterTrigger = probe.count;

    // loading -> tik -> "Katiliyorsun": ~1.3 sn, kare kare.
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final afterAnimation = probe.count;

    // Butce: ucu de icerik degisiminin kendi karesi (metin -> spinner,
    // spinner -> tik, tik -> "Katiliyorsun"). Butonun genisligi bu uc anda
    // degisir ve ust satir yeniden yerlesir. Kare basina maliyet yok.
    expect(
      afterAnimation - afterTrigger,
      lessThanOrEqualTo(3),
      reason:
          'tik/boyut gecisi sayfanin geri kalanini yeniden cizdi '
          '(${afterAnimation - afterTrigger} fazla boyama)',
    );

    // Animasyon gercekten calisti.
    expect(find.text('Katılıyorsun'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

class _Probe extends CustomPainter {
  int count = 0;

  @override
  void paint(Canvas canvas, Size size) => count++;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
