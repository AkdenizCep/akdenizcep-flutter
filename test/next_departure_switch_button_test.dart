import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/pages/components/next_departure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Değiştir" butonundaki oklar her basista kendi etrafinda bir tam tur atar.
/// Tur dokunusla birikir: art arda basista ikon basa sicramaz, bulundugu
/// yerden bir tur daha doner.
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

  Widget app({VoidCallback? onSwitch, bool disableAnimations = false}) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: NextDepartureCard(
              lines: lines,
              originName: 'Adli Tıp',
              destinationName: 'Meltem Kapısı',
              fallbackTitle: 'Gidiş',
              canSwitchDirection: true,
              onSwitchDirection: onSwitch ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  final icon = find.byIcon(Icons.swap_horiz_rounded);
  final rotation = find.ancestor(
    of: icon,
    matching: find.byType(AnimatedRotation),
  );
  final transition = find.ancestor(
    of: icon,
    matching: find.byType(RotationTransition),
  );

  double angle(WidgetTester tester) =>
      tester.widget<RotationTransition>(transition).turns.value;

  testWidgets('basmadan once oklar donmemis durumdadir', (tester) async {
    await tester.pumpWidget(app());

    expect(tester.widget<AnimatedRotation>(rotation).turns, 0);
    expect(angle(tester), 0);
  });

  testWidgets('basinca oklar bir tam tur atar ve ayni yerde durur', (
    tester,
  ) async {
    var switched = 0;
    await tester.pumpWidget(app(onSwitch: () => switched++));

    await tester.tap(find.text('Değiştir'));
    expect(switched, 1, reason: 'yon degisimi animasyonu beklemez');

    // Animasyonun ortasinda: ne baslangicta ne bitiste.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(angle(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(angle(tester), 1);
  });

  testWidgets('art arda basista tur birikir, basa sicramaz', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Değiştir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final midway = angle(tester);

    // Hedef 1 -> 2; ikon ortadaki konumundan devam eder, 0'a donmez.
    await tester.tap(find.text('Değiştir'));
    await tester.pump();
    expect(angle(tester), closeTo(midway, 0.2));
    expect(angle(tester), greaterThanOrEqualTo(midway));

    await tester.pumpAndSettle();
    expect(angle(tester), 2);
  });

  testWidgets('animasyonlar kapaliysa oklar beklemeden son konuma gecer', (
    tester,
  ) async {
    var switched = 0;
    await tester.pumpWidget(
      app(onSwitch: () => switched++, disableAnimations: true),
    );

    await tester.tap(find.text('Değiştir'));
    await tester.pump();

    expect(switched, 1);
    expect(angle(tester), 1);
  });
}
