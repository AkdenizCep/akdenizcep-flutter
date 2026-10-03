import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/departure_strip.dart';
import 'package:akdenizcep/features/ring/pages/components/nearby_stops_row.dart';
import 'package:akdenizcep/features/ring/pages/components/next_departure_card.dart';
import 'package:akdenizcep/features/ring/pages/components/ring_search_bar.dart';
import 'package:akdenizcep/features/ring/pages/components/stop_list_tile.dart';
import 'package:akdenizcep/features/ring/pages/ring_page.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Ulasim ana ekrani (9a) regresyon testleri.
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
      servedBy: [service('AÜ102', sequence: 2), service('AÜ103', sequence: 3)],
    ),
  ];

  final singleLine = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['06:31', '23:55'],
      weekend: const ['10:30'],
    ),
  ];

  // 2026-07-27 Pazartesi.
  final twoPointSchedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['14:15', '14:30', '14:45'],
      weekend: const [],
    ),
    RingSchedule(
      lineId: 'au103_gidis',
      weekday: const ['14:20', '14:35', '14:50'],
      weekend: const [],
    ),
    RingSchedule(
      lineId: 'au102_donus',
      weekday: const ['14:00', '14:40'],
      weekend: const [],
    ),
    RingSchedule(
      lineId: 'au103_donus',
      weekday: const ['14:10', '14:55'],
      weekend: const [],
    ),
  ];

  List<NearbyStop> nearbyFor(List<RingSchedule> schedules) => [
    for (final stop in stops)
      NearbyStop(
        stop: stop,
        distanceMeters: stop.id == 'durak_1' ? 76 : 553,
        schedules: schedules,
      ),
  ];

  Widget app(
    Widget home, {
    required List<RingSchedule> schedules,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime(2026, 7, 27, 23, 43);
    final nearby = nearbyFor(schedules);

    return ProviderScope(
      overrides: [
        // Konum ve Firebase'e hic dokunmadan gercek veri sekli saglanir.
        nearbyStopsProvider.overrideWith((ref) => nearby),
        nearestStopProvider.overrideWith((ref) => nearby.first),
        ringStopsProvider.overrideWith((ref) => stops),
        ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
        routeShapesProvider.overrideWith((ref) async => routeBundle()),
        // Geri sayim testte sabit kalsin — saat ilerledikce test degismesin.
        nowProvider.overrideWith((ref) => effectiveNow),
        // Fixture'lar hafta ici tarifesi; testin kosuldugu gercek gun tipi
        // sonucu degistirmesin.
        showWeekendProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(home: home),
    );
  }

  Widget strip({required List<RingSchedule> schedules, DateTime? now}) => app(
    // Ana ekrandaki kisit zinciri: dikey kaydirma -> sinirsiz yukseklik.
    const Scaffold(body: SingleChildScrollView(child: NearbyStopsRow())),
    schedules: schedules,
    now: now,
  );

  testWidgets('yakindaki duraklar seridi sinirsiz yukseklikte cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(strip(schedules: singleLine));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('YAKINDAKİ DURAKLAR'), findsOneWidget);
    // Ham GTFS adi degil, sadelestirilmis ad gosterilir.
    expect(find.text('Merkezi Yemekhane'), findsOneWidget);
    expect(find.text('İletişim Fakültesi'), findsOneWidget);
    expect(find.text('76 m · ~1 dk yürüme'), findsOneWidget);
    // 23:43 -> 23:55 arasi 12 dakika; iki kartta da.
    expect(find.text('12'), findsNWidgets(2));
    expect(find.text('dk sonra'), findsNWidgets(2));
  });

  testWidgets('kart hatlari rozetler ve geri sayim hat rozeti gosterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      strip(
        schedules: [
          RingSchedule(
            lineId: 'au102_gidis',
            weekday: const ['08:55'],
            weekend: const [],
          ),
          RingSchedule(
            lineId: 'au103_gidis',
            weekday: const ['08:51'],
            weekend: const [],
          ),
        ],
        now: DateTime(2026, 7, 27, 8, 48),
      ),
    );
    await tester.pumpAndSettle();

    // Iki hat da gecen durakta en erken kalkis AÜ103'unkidir (3 dk).
    expect(find.text('3'), findsOneWidget);
    expect(find.text('AÜ103'), findsWidgets);
    expect(find.text('HATLAR'), findsNWidgets(2));
    // Yalnizca AÜ102 gecen durakta tek rozet, bos slot yok.
    expect(find.text('AÜ102'), findsWidgets);
  });

  testWidgets('bir saati asan geri sayim karta tasmaz', (tester) async {
    await tester.pumpWidget(
      strip(schedules: singleLine, now: DateTime(2026, 7, 27, 8, 23)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('15 sa 32 dk sonra'), findsNWidgets(2));
  });

  testWidgets('bugun sefer kalmadiysa Bugun bitti yazar, rozet gizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      strip(schedules: singleLine, now: DateTime(2026, 7, 27, 23, 59)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bugün bitti'), findsNWidgets(2));
    expect(find.text('dk sonra'), findsNothing);
  });

  testWidgets('ulasim ana ekrani butun halinde hatasiz cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ulaşım'), findsOneWidget);
    expect(find.text('YAKINDAKİ DURAKLAR'), findsOneWidget);
    expect(find.text('Haritada Gör'), findsOneWidget);
    expect(find.text('Tüm Tarife'), findsOneWidget);
    // Hero kart: yon basligi.
    expect(find.text('YÖN'), findsOneWidget);
  });

  testWidgets('hero kart yonu ve her hattin siradaki kalkisini gosterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    final card = find.byType(NextDepartureCard);
    Finder inCard(Finder finder) =>
        find.descendant(of: card, matching: finder);

    expect(
      inCard(find.textContaining('Adli Tıp', findRichText: true)),
      findsOneWidget,
    );
    expect(
      inCard(find.textContaining('Meltem Kapısı', findRichText: true)),
      findsOneWidget,
    );
    expect(inCard(find.text('AÜ102')), findsOneWidget);
    expect(inCard(find.text('AÜ103')), findsOneWidget);

    // 14:22 -> AÜ102'nin sirasi 14:30, AÜ103'unki 14:35; ikisi de buyuk.
    double sizeOf(String time) =>
        tester.widget<Text>(inCard(find.text(time))).style!.fontSize!;
    expect(sizeOf('14:30'), greaterThan(sizeOf('14:15')));
    expect(sizeOf('14:35'), greaterThan(sizeOf('14:20')));
    expect(sizeOf('14:30'), sizeOf('14:35'));
  });

  testWidgets('Degistir butonu yonu cevirir, saatler ve baslik degisir', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();

    final card = find.byType(NextDepartureCard);
    Finder inCard(Finder finder) =>
        find.descendant(of: card, matching: finder);

    // Donus: Meltem Kapisi -> Adli Tip. Iki ad ayri parcalar oldugu icin
    // sirayi yatay konumlari belirler: Meltem solda, Adli sagda.
    expect(
      tester.getTopLeft(inCard(find.text('Meltem Kapısı'))).dx,
      lessThan(tester.getTopLeft(inCard(find.text('Adli Tıp'))).dx),
    );
    expect(inCard(find.text('14:30')), findsNothing);
    // 14:22 -> AÜ102 donus sirasi 14:40, AÜ103 donus sirasi 14:55.
    expect(inCard(find.text('14:40')), findsOneWidget);
    expect(inCard(find.text('14:55')), findsOneWidget);
  });

  testWidgets('hero kart, arama satiri ve yakindaki duraklar bu sirada dizilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(NextDepartureCard));
    final search = tester.getRect(find.byType(RingSearchBar));
    final star = tester.getCenter(find.byIcon(Icons.star_rounded));
    final nearby = tester.getTopLeft(find.text('YAKINDAKİ DURAKLAR'));

    // Hero kartin hemen altinda arama cubugu.
    expect(search.top, greaterThanOrEqualTo(card.bottom));
    // Favori duraklar butonu aramanin sag tarafinda, ayni satirda.
    expect(star.dx, greaterThan(search.right));
    expect(star.dy, closeTo(search.center.dy, 1));
    // Yakindaki duraklar arama satirinin altinda.
    expect(nearby.dy, greaterThan(search.bottom));
  });

  testWidgets('arama yazilinca yakindaki duraklar sonuclarla degisir', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fakülte');
    await tester.pumpAndSettle();

    expect(find.text('YAKINDAKİ DURAKLAR'), findsNothing);
    expect(find.byType(StopListTile), findsOneWidget);
    // Hero kart arama sirasinda da yerinde kalir.
    expect(find.byType(NextDepartureCard), findsOneWidget);
  });

  testWidgets('Degistir butonu dokunusa cevap verir', (tester) async {
    var switched = false;

    await tester.pumpWidget(
      _cardApp(
        lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))],
        onSwitchDirection: () => switched = true,
      ),
    );

    await tester.tap(find.text('Değiştir'));
    await tester.pump();
    expect(switched, isTrue);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tek yonlu veride Degistir butonu gizlenir', (tester) async {
    await tester.pumpWidget(
      _cardApp(
        lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))],
        canSwitchDirection: false,
      ),
    );

    expect(find.text('Değiştir'), findsNothing);
  });

  testWidgets('guzergah adi yoksa baslik Gidis/Donus etiketine duser', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardApp(
        lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))],
        originName: null,
        destinationName: null,
        fallbackTitle: 'Dönüş',
      ),
    );

    expect(find.text('Dönüş'), findsOneWidget);
  });

  testWidgets('siradaki kalkis seridin ortasinda durur', (tester) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))]),
    );
    await tester.pumpAndSettle();

    final strip = tester.getRect(find.byType(DepartureStrip));
    final next = tester.getCenter(find.text('08:30'));

    expect(next.dx, closeTo(strip.center.dx, 1));
  });

  testWidgets('gunun ilk kalkisi da ortalanir', (tester) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 5, 0))]),
    );
    await tester.pumpAndSettle();

    final strip = tester.getRect(find.byType(DepartureStrip));
    final first = tester.getCenter(find.text('06:30'));

    expect(first.dx, closeTo(strip.center.dx, 1));
  });

  testWidgets('saat seridi yatay kaydirilir', (tester) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))]),
    );
    await tester.pumpAndSettle();

    final before = tester.getCenter(find.text('08:30')).dx;

    await tester.drag(find.byType(DepartureStrip), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(tester.getCenter(find.text('08:30')).dx, lessThan(before - 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('baslangica 60 px kala biten kaydirma baslangica doner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))]),
    );
    await tester.pumpAndSettle();

    final center = tester.getRect(find.byType(DepartureStrip)).center.dx;

    await tester.drag(find.byType(DepartureStrip), const Offset(-50, 0));
    await tester.pumpAndSettle();

    expect(tester.getCenter(find.text('08:30')).dx, closeTo(center, 1));
  });

  testWidgets('baslangictan 60 px uzakta biten kaydirma oldugu yerde kalir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 8, 10))]),
    );
    await tester.pumpAndSettle();

    final center = tester.getRect(find.byType(DepartureStrip)).center.dx;

    await tester.drag(find.byType(DepartureStrip), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(tester.getCenter(find.text('08:30')).dx, lessThan(center - 80));
  });

  testWidgets('sirali sefer ilerleyince serit yeni saate kayar', (
    tester,
  ) async {
    final clock = ValueNotifier(DateTime(2026, 7, 27, 8, 10));
    addTearDown(clock.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<DateTime>(
        valueListenable: clock,
        builder: (_, now, _) => _cardApp(lines: [_line('au102', now: now)]),
      ),
    );
    await tester.pumpAndSettle();

    clock.value = DateTime(2026, 7, 27, 8, 31);
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byType(DepartureStrip));
    expect(
      tester.getCenter(find.text('09:00')).dx,
      closeTo(rect.center.dx, 1),
    );
  });

  testWidgets('bugun sefer kalmadiysa yarinin ilk kalkisi vurgulanir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardApp(lines: [_line('au102', now: DateTime(2026, 7, 27, 23, 59))]),
    );
    await tester.pumpAndSettle();

    expect(find.text('yarın'), findsOneWidget);
    // Yarin (sali) da hafta ici: ilk kalkis yine 06:30. Seritte iki kez gecer
    // (bugunun ilki, soluk; yarinin ilki, buyuk).
    expect(find.text('06:30'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data == '06:30' && w.style?.fontSize == 30,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saati olmayan hat bos serit yerine aciklama gosterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardApp(
        lines: [
          LineDepartures(
            lineCode: 'au102',
            departures: RingDepartures.from(
              weekdayTimes: const [],
              weekendTimes: const [],
              showWeekend: false,
              now: DateTime(2026, 7, 27, 8, 10),
            ),
          ),
        ],
      ),
    );

    expect(find.text('Sefer saati girilmemiş'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Haritada Gor ve Tum Tarife kartlari ayni yukseklikte', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const RingPage(), schedules: twoPointSchedules, now: _monday1422),
    );
    await tester.pumpAndSettle();

    double heightOf(String label) => tester
        .getSize(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate(
                  (w) => w is SizedBox && w.height == 112,
                ),
              )
              .first,
        )
        .height;

    expect(heightOf('Haritada Gör'), 112);
    expect(heightOf('Tüm Tarife'), 112);
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
}

final _monday1422 = DateTime(2026, 7, 27, 14, 22);

/// Yarim saatlik seferleri olan bir hat; 06:30'dan 22:00'a, hafta ici.
LineDepartures _line(String lineCode, {required DateTime now}) {
  final times = [
    for (var minutes = 6 * 60 + 30; minutes <= 22 * 60; minutes += 30)
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
          '${(minutes % 60).toString().padLeft(2, '0')}',
  ];

  return LineDepartures(
    lineCode: lineCode,
    departures: RingDepartures.from(
      weekdayTimes: times,
      weekendTimes: const [],
      showWeekend: false,
      now: now,
    ),
  );
}

/// Hero karti sayfadaki kisit zinciriyle (yatay dolgu, sinirsiz yukseklik)
/// tek basina cizer.
Widget _cardApp({
  required List<LineDepartures> lines,
  String? originName = 'Adli Tıp',
  String? destinationName = 'Meltem Kapısı',
  String fallbackTitle = 'Gidiş',
  bool canSwitchDirection = true,
  VoidCallback? onSwitchDirection,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: NextDepartureCard(
            lines: lines,
            originName: originName,
            destinationName: destinationName,
            fallbackTitle: fallbackTitle,
            canSwitchDirection: canSwitchDirection,
            onSwitchDirection: onSwitchDirection ?? () {},
          ),
        ),
      ),
    ),
  );
}
