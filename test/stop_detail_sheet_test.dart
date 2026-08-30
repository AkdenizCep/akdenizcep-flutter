import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/stop_detail_sheet.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Durak yapragi: hat/yon grubu yok, tek kronolojik liste.
///
/// Dil kurali burada da baglayici — universite durak bazli saat yayinlamadigi
/// icin hicbir satir "varis" demez; gosterilen her saat hattin kalkis
/// noktasindan ayrilma zamanidir.
void main() {
  final stops = [
    stop(
      'durak_1',
      name: 'AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE',
      servedBy: [service('AÜ102'), service('AÜ103', isReturn: true)],
    ),
    stop('durak_3', name: 'İLETİŞİM FAKÜLTESİ', servedBy: [service('AÜ103')]),
  ];

  // AU102 gidis: durak_1 -> durak_3, kalkislar 08:55 / 09:09
  // AU103 donus: durak_3 -> durak_1, kalkislar 08:51 / 09:01 / 09:11
  final schedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['06:31', '08:55', '09:09'],
      weekend: const [],
      stops: const ['durak_1', 'durak_3'],
    ),
    RingSchedule(
      lineId: 'au103_donus',
      weekday: const ['06:41', '08:51', '09:01', '09:11'],
      weekend: const [],
      stops: const ['durak_3', 'durak_1'],
    ),
  ];

  final nearby = [
    NearbyStop(
      stop: stops.first,
      distanceMeters: 553,
      schedules: schedules,
    ),
  ];

  Widget wrap({required DateTime now, List<NearbyStop>? stopsOverride}) {
    return ProviderScope(
      overrides: [
        nearbyStopsProvider.overrideWith((ref) => stopsOverride ?? nearby),
        ringStopsProvider.overrideWith((ref) => stops),
        ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
        // Yon etiketleri guzergah verisinden okunuyor.
        routeShapesProvider.overrideWith((ref) => routeBundle()),
        nowProvider.overrideWith((ref) => now),
        // showWeekendProvider'in varsayilani GERCEK DateTime.now()'a bakar
        // (uygulama gercek zamanda calisirken dogru olan budur). Test sahte
        // bir `now` enjekte ettigi icin bu da ayni sahte `now`'a gore
        // override edilmezse, test HAFTA SONU bir gunde calistirildiginda
        // (showWeekend=true baslar) sahte `now` hafta ici bir gunu simule
        // ediyorsa "bugun" hesabi celisip tum kalkislar listeden duser.
        showWeekendProvider.overrideWith(
          (ref) => RingDepartures.isWeekendDay(now),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: StopDetailSheet(stopId: 'durak_1')),
      ),
    );
  }

  testWidgets('iki hattin kalkislari tek kronolojik listede birlesir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 8, 48)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SIRADAKİ KALKIŞLAR'), findsOneWidget);
    expect(find.text('Merkezi Yemekhane'), findsOneWidget);
    expect(find.text('553 m · ~7 dk yürüme'), findsOneWidget);

    // Satirlar zamana gore: 08:51 (AU103) once, sonra 08:55 (AU102).
    final times = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();

    final firstRow = times.indexWhere((t) => t.startsWith('08:51'));
    final secondRow = times.indexWhere((t) => t.startsWith('08:55'));
    expect(firstRow, greaterThanOrEqualTo(0));
    expect(secondRow, greaterThan(firstRow));
  });

  testWidgets('ilk satir geri sayimi dakika olarak gosterir', (tester) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 8, 48)));
    await tester.pumpAndSettle();

    // 08:48 -> 08:51 = 3 dakika.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('DAKİKA'), findsWidgets);
  });

  testWidgets('satir "sonrasi" bilgisini kendi tarifesinden alir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 8, 48)));
    await tester.pumpAndSettle();

    expect(find.text('08:51 · sonrası 09:01 · 09:11'), findsOneWidget);
    expect(find.text('08:55 · sonrası 09:09'), findsOneWidget);
  });

  testWidgets('yon metni hat rozetinin yaninda durur', (tester) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 8, 48)));
    await tester.pumpAndSettle();

    expect(find.text('AÜ102'), findsWidgets);
    expect(find.text('AÜ103'), findsWidgets);
    // Yon metni artik guzergah etiketinden geliyor.
    expect(find.text('Meltem Kapısı yönü'), findsWidgets);
    expect(find.text('Adli Tıp yönü'), findsWidgets);
  });

  testWidgets('bugun bittiyse yarinin ilk kalkisina duser', (tester) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 23, 30)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('BUGÜNÜN SEFERLERİ BİTTİ'), findsOneWidget);
    expect(find.text('SIRADAKİ KALKIŞLAR'), findsNothing);
    expect(find.text('Yarın ilk kalkış 06:31'), findsOneWidget);
    expect(find.text('Yarın ilk kalkış 06:41'), findsOneWidget);
    expect(find.text('YARIN'), findsNWidgets(2));
  });

  testWidgets('hat girilmemisse mevcut metin korunur', (tester) async {
    await tester.pumpWidget(
      wrap(
        now: DateTime(2026, 7, 27, 8, 48),
        stopsOverride: [
          NearbyStop(
            stop: stops.first,
            distanceMeters: null,
            schedules: const [],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Bu duraktan geçen hat bilgisi girilmemiş.'),
      findsOneWidget,
    );
  });

  testWidgets('kalkis dili korunur — hicbir satir "varis" demez', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 8, 48)));
    await tester.pumpAndSettle();

    expect(find.text('Saatler hattın kalkış noktasına aittir.'), findsOneWidget);
    expect(find.textContaining('varış'), findsNothing);
    expect(find.textContaining('gelir'), findsNothing);
  });
}
