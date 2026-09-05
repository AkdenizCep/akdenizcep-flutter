import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/nearby_stops_row.dart';
import 'package:akdenizcep/features/ring/pages/components/next_departure_card.dart';
import 'package:akdenizcep/features/ring/pages/ring_page.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:akdenizcep/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Ulasim ana ekranindaki iki bilesenin duzen ve dokunma regresyon testleri.
///
/// Gecmisi: yakindaki duraklar seridi, yatay kaydirilan bir `Row` icinde
/// `CrossAxisAlignment.stretch` kullaniyordu. Dikey kisit sinirsiz oldugu icin
/// bu, layout sirasinda exception firlatiyor ve bolum ekranda hic
/// gorunmuyordu.
void main() {
  final stops = [
    stop(
      'durak_1',
      name: 'AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE',
      servedBy: [service('AÜ102')],
    ),
    stop(
      'durak_2',
      name: 'İLETİŞİM FAKÜLTESİ',
      servedBy: [service('AÜ102', sequence: 2)],
    ),
  ];

  final schedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['06:31', '23:55'],
      weekend: const ['10:30'],
      stops: const ['durak_1', 'durak_2'],
    ),
  ];

  final nearby = [
    for (final stop in stops)
      NearbyStop(
        stop: stop,
        distanceMeters: stop.id == 'durak_1' ? 76 : 553,
        schedules: schedules,
      ),
  ];

  Widget wrap(Widget child, {DateTime? now}) {
    final effectiveNow = now ?? DateTime(2026, 7, 27, 23, 43);
    return ProviderScope(
      overrides: [
        // Konum ve Firebase'e hic dokunmadan gercek veri sekli saglanir.
        nearbyStopsProvider.overrideWith((ref) => nearby),
        nearestStopProvider.overrideWith((ref) => nearby.first),
        ringStopsProvider.overrideWith((ref) => stops),
        ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
        // Geri sayim testte sabit kalsin — saat ilerledikce test degismesin.
        nowProvider.overrideWith((ref) => effectiveNow),
        // showWeekendProvider'in varsayilani GERCEK DateTime.now()'a bakar;
        // testin sahte `now`'i ile tutarli olmazsa (ör. test hafta sonu bir
        // gunde calistirilirsa) "bugun" hesabi celisip kalkislar kaybolur.
        // Bkz. stop_detail_sheet_test.dart'taki ayni duzeltme.
        showWeekendProvider.overrideWith(
          (ref) => RingDepartures.isWeekendDay(effectiveNow),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          // Ana ekrandaki kisit zinciri: dikey kaydirma -> sinirsiz yukseklik.
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('yakindaki duraklar seridi sinirsiz yukseklikte cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const NearbyStopsRow()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('YAKINDAKİ DURAKLAR'), findsOneWidget);
    // Ham GTFS adi degil, sadelestirilmis ad gosterilir.
    expect(find.text('Merkezi Yemekhane'), findsOneWidget);
    expect(find.text('İletişim Fakültesi'), findsOneWidget);
    // 23:43 -> 23:55 arasi 12 dakika.
    expect(find.text('12'), findsNWidgets(2));
  });

  testWidgets('bir saati asan geri sayim 176px karta tasmaz', (tester) async {
    await tester.pumpWidget(
      wrap(const NearbyStopsRow(), now: DateTime(2026, 7, 27, 8, 23)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('15 sa 32 dk sonra'), findsNWidgets(2));
  });

  testWidgets('ulasim ana ekrani butun halinde hatasiz cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyStopsProvider.overrideWith((ref) => nearby),
          nearestStopProvider.overrideWith((ref) => nearby.first),
          ringStopsProvider.overrideWith((ref) => stops),
          ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
          nowProvider.overrideWith((ref) => DateTime(2026, 7, 27, 23, 43)),
          showWeekendProvider.overrideWith(
            (ref) => RingDepartures.isWeekendDay(DateTime(2026, 7, 27, 23, 43)),
          ),
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: RingPage()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ulaşım'), findsOneWidget);
    expect(find.text('YAKINDAKİ DURAKLAR'), findsOneWidget);
    expect(find.text('Haritada Gör'), findsOneWidget);
    // Hero seridi: onceki / sonraki / son sefer.
    expect(find.text('SON SEFER'), findsOneWidget);
  });

  testWidgets('tarife okunamazsa sonsuz loading yerine yeniden deneme sunar', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ringSchedulesProvider.overrideWith((ref) {
            attempts++;
            return Stream<List<RingSchedule>>.error(
              Exception('Ring tarifesine ulaşılamadı.'),
            );
          }),
        ],
        child: const MaterialApp(home: RingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ring tarifesine ulaşılamadı.'), findsOneWidget);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('hero karttaki hat ve yon butonlari dokunusa cevap verir', (
    tester,
  ) async {
    String? changedLine;
    var switched = false;

    await tester.pumpWidget(
      wrap(
        NextDepartureCard(
          departures: RingDepartures.from(
            weekdayTimes: const ['06:31', '23:55'],
            weekendTimes: const [],
            showWeekend: false,
            now: DateTime(2026, 7, 27, 8, 0),
          ),
          activeLine: 'au102',
          availableLines: const ['au102', 'au103'],
          directionSummary: 'durak_2 yönü',
          originName: 'durak_1',
          canSwitchDirection: true,
          onLineChanged: (line) => changedLine = line,
          onSwitchDirection: () => switched = true,
        ),
      ),
    );

    await tester.tap(find.text('AÜ103'));
    await tester.pump();
    expect(changedLine, 'au103');

    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pump();
    expect(switched, isTrue);

    expect(tester.takeException(), isNull);
  });
}
