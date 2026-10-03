import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/pages/components/departure_strip.dart';
import 'package:akdenizcep/features/ring/pages/components/next_departure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saat seridi: icerik (yon/gun) degisince kaydirma konumu **bir kare gec**
/// duzelir. O karede yeni saatler eski konumda cizilir: vurgulanan saat ekran
/// disinda kalir, serit rastgele soluk saatler gosterir, sonraki karede
/// merkeze atlar. Bu bir "takilma" olarak gorunur.
///
/// Kural: ekrana giden hicbir karede icerik ile konum uyusmazligi gorunmez.
/// Yani her cizilen karede serit ya gorunmezdir ya da vurgulanan saat tam
/// ortadadir.
void main() {
  List<String> times(int startMinutes, int step, int count) => [
    for (var i = 0; i < count; i++)
      '${((startMinutes + i * step) ~/ 60).toString().padLeft(2, '0')}:'
          '${((startMinutes + i * step) % 60).toString().padLeft(2, '0')}',
  ];

  RingDepartures departures(List<String> t, {DateTime? now}) =>
      RingDepartures.from(
        weekdayTimes: t,
        weekendTimes: const [],
        showWeekend: false,
        now: now ?? DateTime(2026, 7, 27, 14, 22),
      );

  // Gidis: 06:00'dan 30 dk arayla (sirada 14:30); donus: 05:05'ten 20 dk
  // arayla (sirada 14:25). Ikisinde de vurgulanan saat farkli bir dizinde.
  final going = departures(times(6 * 60, 30, 36));
  final back = departures(times(5 * 60 + 5, 20, 54));

  Widget host(
    ValueNotifier<RingDepartures> value, {
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 60,
            child: ValueListenableBuilder<RingDepartures>(
              valueListenable: value,
              builder: (context, d, _) =>
                  DepartureStrip(key: const ValueKey('au102'), departures: d),
            ),
          ),
        ),
      ),
    );
  }

  final highlight = find.byWidgetPredicate(
    (w) => w is Text && w.style?.fontSize == 30,
  );
  final strip = find.byType(DepartureStrip);

  double offCenter(WidgetTester tester) =>
      tester.getCenter(highlight).dx - tester.getCenter(strip).dx;

  /// Seridin gorunurlugu; saydamlik katmani yoksa tam gorunur sayilir.
  double opacity(WidgetTester tester) {
    final fades = find.descendant(
      of: strip,
      matching: find.byType(FadeTransition),
    );
    if (fades.evaluate().isEmpty) return 1;
    return tester.widget<FadeTransition>(fades.first).opacity.value;
  }

  /// Her **cizilen** kareyi, post-frame callback'lerden once, kaydeder: ekrana
  /// giden goruntu budur. `pump` sonrasi okuma bunu yakalayamaz, cunku o ana
  /// kadar duzeltme zaten uygulanmistir.
  List<({double opacity, double offCenter})> recordPaintedFrames(
    WidgetTester tester,
  ) {
    final frames = <({double opacity, double offCenter})>[];
    var active = true;
    addTearDown(() => active = false);

    tester.binding.addPersistentFrameCallback((_) {
      if (!active || highlight.evaluate().length != 1) return;
      frames.add((opacity: opacity(tester), offCenter: offCenter(tester)));
    });
    return frames;
  }

  void expectNoStaleFrame(List<({double opacity, double offCenter})> frames) {
    expect(frames, isNotEmpty);
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      expect(
        f.opacity == 0 || f.offCenter.abs() < 1,
        isTrue,
        reason:
            'cizilen kare ${i + 1}: serit gorunur (opaklik ${f.opacity}) ama '
            'vurgulanan saat merkezden ${f.offCenter.toStringAsFixed(1)} px '
            'uzakta',
      );
    }
  }

  testWidgets('yon degisince eski konumda yeni saatler cizilmez', (
    tester,
  ) async {
    final value = ValueNotifier(going);
    await tester.pumpWidget(host(value));
    await tester.pumpAndSettle();
    expect(offCenter(tester).abs(), lessThan(1));

    final frames = recordPaintedFrames(tester);
    value.value = back;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expectNoStaleFrame(frames);
  });

  testWidgets('yon degisimi sonunda yeni saat ortalanmis ve tam gorunur', (
    tester,
  ) async {
    final value = ValueNotifier(going);
    await tester.pumpWidget(host(value));
    await tester.pumpAndSettle();

    value.value = back;
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(highlight).data, '14:25');
    expect(offCenter(tester).abs(), lessThan(1));
    expect(opacity(tester), 1);
  });

  testWidgets('ilk kurulumda da yanlis konumdaki saatler cizilmez', (
    tester,
  ) async {
    final value = ValueNotifier(going);
    final frames = recordPaintedFrames(tester);

    await tester.pumpWidget(host(value));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expectNoStaleFrame(frames);
    expect(offCenter(tester).abs(), lessThan(1));
    expect(opacity(tester), 1);
  });

  testWidgets('ayni tarifede siradaki sefer ilerlerse serit gizlenmez', (
    tester,
  ) async {
    // Saat 14:22 -> 14:31: ayni liste, sirada 14:30'dan 15:00'a kayar.
    final value = ValueNotifier(going);
    await tester.pumpWidget(host(value));
    await tester.pumpAndSettle();

    final opacities = <double>[];
    var active = true;
    addTearDown(() => active = false);
    tester.binding.addPersistentFrameCallback((_) {
      if (active) opacities.add(opacity(tester));
    });

    value.value = departures(
      times(6 * 60, 30, 36),
      now: DateTime(2026, 7, 27, 14, 31),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(opacities, isNotEmpty);
    expect(opacities.every((o) => o == 1), isTrue, reason: '$opacities');
    expect(tester.widget<Text>(highlight).data, '15:00');
    expect(offCenter(tester).abs(), lessThan(1));
  });

  testWidgets('saatsiz bir tarife araya girse de serit sonunda gorunur', (
    tester,
  ) async {
    final value = ValueNotifier(going);
    await tester.pumpWidget(host(value));
    await tester.pumpAndSettle();

    value.value = departures(const []);
    await tester.pumpAndSettle();
    expect(find.text('Sefer saati girilmemiş'), findsOneWidget);

    value.value = back;
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(highlight).data, '14:25');
    expect(offCenter(tester).abs(), lessThan(1));
    expect(opacity(tester), 1);
  });

  testWidgets('animasyonlar kapaliyken de bayat kare cizilmez', (tester) async {
    final value = ValueNotifier(going);
    await tester.pumpWidget(host(value, reduceMotion: true));
    await tester.pumpAndSettle();

    final frames = recordPaintedFrames(tester);
    value.value = back;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expectNoStaleFrame(frames);
    expect(offCenter(tester).abs(), lessThan(1));
    expect(opacity(tester), 1);
  });

  testWidgets('hero kartta Degistir butonu hicbir seritte bayat kare cizdirmez', (
    tester,
  ) async {
    // Iki hat, iki yon: gercek karttaki gibi her satir kendi seridini tasir.
    List<LineDepartures> linesFor(bool isReturn) => [
      LineDepartures(lineCode: 'au102', departures: isReturn ? back : going),
      LineDepartures(
        lineCode: 'au103',
        departures: isReturn
            ? departures(times(5 * 60 + 15, 25, 48))
            : departures(times(6 * 60 + 10, 40, 28)),
      ),
    ];

    final isReturn = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ValueListenableBuilder<bool>(
                valueListenable: isReturn,
                builder: (context, value, _) => NextDepartureCard(
                  lines: linesFor(value),
                  originName: value ? 'Meltem Kapısı' : 'Adli Tıp',
                  destinationName: value ? 'Adli Tıp' : 'Meltem Kapısı',
                  fallbackTitle: 'Gidiş',
                  canSwitchDirection: true,
                  onSwitchDirection: () => isReturn.value = !isReturn.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strips = find.byType(DepartureStrip);
    expect(strips, findsNWidgets(2));
    final stale = <String>[];
    var active = true;
    addTearDown(() => active = false);
    var frame = 0;
    tester.binding.addPersistentFrameCallback((_) {
      // Test bitiminde agac sifirlanirken serit kalmaz.
      if (!active || strips.evaluate().length != 2) return;
      frame++;
      for (var i = 0; i < 2; i++) {
        final strip = strips.at(i);
        final big = find.descendant(
          of: strip,
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.style?.fontSize == 30,
          ),
        );
        if (big.evaluate().length != 1) continue;
        final fades = find.descendant(
          of: strip,
          matching: find.byType(FadeTransition),
        );
        final visible = fades.evaluate().isEmpty
            ? 1.0
            : tester.widget<FadeTransition>(fades.first).opacity.value;
        final off = (tester.getCenter(big).dx - tester.getCenter(strip).dx)
            .abs();
        if (visible > 0 && off >= 1) {
          stale.add(
            'kare $frame, serit ${i + 1}: opaklik $visible, sapma ${off.toStringAsFixed(1)} px',
          );
        }
      }
    });

    await tester.tap(find.text('Değiştir'));
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(stale, isEmpty, reason: stale.join('\n'));
    for (var i = 0; i < 2; i++) {
      final big = find.descendant(
        of: strips.at(i),
        matching: find.byWidgetPredicate(
          (w) => w is Text && w.style?.fontSize == 30,
        ),
      );
      expect(
        (tester.getCenter(big).dx - tester.getCenter(strips.at(i)).dx).abs(),
        lessThan(1),
      );
    }
  });
}
