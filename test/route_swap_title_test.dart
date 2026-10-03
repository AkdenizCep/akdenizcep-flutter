import 'package:akdenizcep/features/ring/pages/components/route_swap_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rota basligi: "Adli Tıp → Meltem Kapısı". Yon degisince iki ad birbirinin
/// yerine animasyonla gecer; oklu ara parca ikisinin arasinda kalir.
///
/// Testlerde yazi tipi Ahem'dir; genislikler cizilen metinden okunur.
void main() {
  const adli = 'Adli Tıp';
  const meltem = 'Meltem Kapısı';
  const style = TextStyle(fontSize: 18, color: Colors.white);

  Widget host(
    ValueNotifier<(String, String)> names, {
    double width = 600,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ValueListenableBuilder<(String, String)>(
              valueListenable: names,
              builder: (context, value, _) => RouteSwapTitle(
                origin: value.$1,
                destination: value.$2,
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double x(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;

  double arrowX(WidgetTester tester) =>
      tester.getCenter(find.byIcon(Icons.arrow_forward_rounded)).dx;

  testWidgets('baslangicta kalkis solda, varis sagda, ok ikisinin arasinda', (
    tester,
  ) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));

    expect(x(tester, adli), lessThan(arrowX(tester)));
    expect(arrowX(tester), lessThan(x(tester, meltem)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('yon degisince adlar birbirinin yerine gecer', (tester) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));
    final adliBefore = x(tester, adli);
    final meltemBefore = x(tester, meltem);
    // Genislikler cizilen metinden okunur: Ahem'de bazi Turkce harfler yedek
    // glifle cizilir, sabit bir sayi yazmak testi kirilgan yapar.
    final adliWidth = tester.getSize(find.text(adli)).width;
    final meltemWidth = tester.getSize(find.text(meltem)).width;

    names.value = (meltem, adli);
    await tester.pumpAndSettle();

    // Meltem artik solda, Adli sagda; ok yine ikisinin arasinda.
    expect(x(tester, meltem), lessThan(arrowX(tester)));
    expect(arrowX(tester), lessThan(x(tester, adli)));

    // Meltem, Adli'nin eski yerine (en sola) gecer; toplam genislik ayni
    // kaldigi icin Adli'nin sag ucu da Meltem'in eski sag ucuna oturur.
    expect(x(tester, meltem), closeTo(adliBefore, 0.01));
    expect(
      x(tester, adli) + adliWidth,
      closeTo(meltemBefore + meltemWidth, 0.01),
    );
  });

  testWidgets('gecis suresince adlar eski ve yeni konumlari arasinda', (
    tester,
  ) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));
    final adliStart = x(tester, adli);
    final meltemStart = x(tester, meltem);

    names.value = (meltem, adli);
    await tester.pump();
    await tester.pump(RouteSwapTitle.swapDuration ~/ 2);

    final adliMid = x(tester, adli);
    final meltemMid = x(tester, meltem);

    await tester.pumpAndSettle();
    final adliEnd = x(tester, adli);
    final meltemEnd = x(tester, meltem);

    // Adli saga, Meltem sola gidiyor; ortada ikisi de yolda.
    expect(adliMid, inExclusiveRange(adliStart, adliEnd));
    expect(meltemMid, inExclusiveRange(meltemEnd, meltemStart));
  });

  testWidgets(
    'gecerken adlar dikeyde ayrilir, yan yana gecerken ust uste binmez',
    (tester) async {
      final names = ValueNotifier((adli, meltem));
      await tester.pumpWidget(host(names));
      final adliY = tester.getTopLeft(find.text(adli)).dy;
      final meltemY = tester.getTopLeft(find.text(meltem)).dy;
      expect(adliY, meltemY);

      names.value = (meltem, adli);
      await tester.pump();
      await tester.pump(RouteSwapTitle.swapDuration ~/ 2);

      // Biri yukari, biri asagi kayar.
      expect(tester.getTopLeft(find.text(adli)).dy, lessThan(adliY));
      expect(tester.getTopLeft(find.text(meltem)).dy, greaterThan(meltemY));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(adli)).dy, adliY);
      expect(tester.getTopLeft(find.text(meltem)).dy, meltemY);
    },
  );

  testWidgets('gecis ortasinda ok soner, bitince geri gelir', (tester) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));

    double arrowAlpha() =>
        tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded)).color!.a;

    expect(arrowAlpha(), 1);

    names.value = (meltem, adli);
    await tester.pump();
    await tester.pump(RouteSwapTitle.swapDuration ~/ 2);
    expect(arrowAlpha(), lessThan(0.2));

    await tester.pumpAndSettle();
    expect(arrowAlpha(), 1);
  });

  testWidgets('art arda iki degisim eski yerlesime doner', (tester) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));
    final adliStart = x(tester, adli);
    final meltemStart = x(tester, meltem);

    names.value = (meltem, adli);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    // Animasyon bitmeden tekrar cevrilir.
    names.value = (adli, meltem);
    await tester.pumpAndSettle();

    expect(x(tester, adli), closeTo(adliStart, 0.01));
    expect(x(tester, meltem), closeTo(meltemStart, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adlar tamamen degisirse animasyonsuz hemen yerlesir', (
    tester,
  ) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names));

    names.value = ('Merkez', 'Kampüs');
    await tester.pump();

    expect(find.text('Merkez'), findsOneWidget);
    expect(find.text('Kampüs'), findsOneWidget);
    expect(find.text(adli), findsNothing);
    expect(x(tester, 'Merkez'), lessThan(arrowX(tester)));
    expect(arrowX(tester), lessThan(x(tester, 'Kampüs')));
  });

  testWidgets('animasyonlar kapaliysa degisim beklemeden biter', (
    tester,
  ) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names, disableAnimations: true));

    names.value = (meltem, adli);
    await tester.pump();

    expect(x(tester, meltem), lessThan(arrowX(tester)));
    expect(arrowX(tester), lessThan(x(tester, adli)));
  });

  testWidgets('dar alanda tasmaz, tek satirda kuculur', (tester) async {
    final names = ValueNotifier((adli, meltem));
    await tester.pumpWidget(host(names, width: 200));

    final rect = tester.getRect(find.byType(RouteSwapTitle));
    expect(rect.width, lessThanOrEqualTo(200));
    expect(tester.takeException(), isNull);

    names.value = (meltem, adli);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopRight(find.text(adli)).dx,
      lessThanOrEqualTo(rect.right + 0.01),
    );
  });

  testWidgets('ekran okuyucuya tek ifade olarak okunur', (tester) async {
    final names = ValueNotifier((adli, meltem));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(names));

    expect(find.bySemanticsLabel('$adli → $meltem'), findsOneWidget);

    names.value = (meltem, adli);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('$meltem → $adli'), findsOneWidget);
    handle.dispose();
  });
}
