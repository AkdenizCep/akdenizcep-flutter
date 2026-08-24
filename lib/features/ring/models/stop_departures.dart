import 'ring_departures.dart';
import 'ring_schedule.dart';
import 'route_key.dart';
import 'route_shape.dart';

/// Bir duraktan gecen tek bir kalkis — hat ve yon bilgisiyle birlikte.
///
/// ONEMLI: [time] ve [until], hattin **kalkis noktasindan** ayrilma zamanini
/// anlatir; bu duraga varis zamani degildir. Universite durak bazli saat
/// yayinlamadigi icin varis hesaplanamaz.
class StopDeparture {
  /// "au102" — gosterim icin [lineLabel]'dan gecirilir.
  final String lineCode;

  /// "durak_3 yönü" — [directionSummary] ciktisi.
  final String direction;

  /// Kalkis saati ("HH:mm").
  final String time;

  /// [time]'a kalan sure.
  final Duration until;

  /// Ayni tarifede bu kalkistan sonraki en fazla iki kalkis.
  final List<String> nextTwo;

  const StopDeparture({
    required this.lineCode,
    required this.direction,
    required this.time,
    required this.until,
    this.nextTwo = const [],
  });
}

/// Bir duraktan gecen **tum tarifelerin** kalkislarini tek kronolojik listede
/// birlestirir.
///
/// Saf Dart — Flutter veya Riverpod bilmez, boylece test edilebilir kalir.
abstract final class StopDepartures {
  /// Yon metni guzergah verisinden okunur: "Meltem Kapısı yönü".
  /// Guzergah bulunamazsa "Gidiş"/"Dönüş"e duser.
  static String _directionOf(RingSchedule schedule, RouteShapeBundle routes) {
    final id = routeShapeIdFor(schedule.lineCode, schedule.isReturn);
    final match = routes.routes.where((r) => r.id == id);
    if (match.isEmpty) return schedule.isReturn ? 'Dönüş' : 'Gidiş';

    final parts = match.first.label.split('·');
    final tail = parts.length > 1 ? parts.last.trim() : '';
    return tail.isEmpty ? (schedule.isReturn ? 'Dönüş' : 'Gidiş') : tail;
  }

  /// Bugun kalan kalkislar, zamana gore sirali.
  ///
  /// Secili gun tipi bugunun gun tipiyle uyusmuyorsa ([RingDepartures.isToday]
  /// `false`) canli geri sayim anlamsizdir; o tarife listeye girmez.
  static List<StopDeparture> merge({
    required List<RingSchedule> schedules,
    required RouteShapeBundle routes,
    required bool showWeekend,
    required DateTime now,
  }) {
    final result = <StopDeparture>[];

    for (final schedule in schedules) {
      final departures = RingDepartures.from(
        weekdayTimes: schedule.weekday,
        weekendTimes: schedule.weekend,
        showWeekend: showWeekend,
        now: now,
      );
      if (!departures.isToday) continue;

      final direction = _directionOf(schedule, routes);

      // Tarifenin bugun kalan tum kalkislari listeye girer; her satirin
      // "sonrasi" bilgisi kendi tarifesinden okunur.
      for (var i = 0; i < departures.upcoming.length; i++) {
        final time = departures.upcoming[i];
        final at = RingDepartures.resolveTime(time, now);
        if (at == null) continue;

        result.add(
          StopDeparture(
            lineCode: schedule.lineCode,
            direction: direction,
            time: time,
            until: at.difference(now),
            nextTwo: departures.upcoming.skip(i + 1).take(2).toList(),
          ),
        );
      }
    }

    result.sort((a, b) {
      final byTime = a.until.compareTo(b.until);
      if (byTime != 0) return byTime;
      return a.lineCode.compareTo(b.lineCode);
    });
    return result;
  }

  /// Bugun sefer kalmadiginda gosterilecek satirlar: hat + yon basina yarinin
  /// ilk kalkisi. [until] anlamsizdir ve `Duration.zero` gelir.
  static List<StopDeparture> tomorrowFirsts({
    required List<RingSchedule> schedules,
    required RouteShapeBundle routes,
    required bool showWeekend,
    required DateTime now,
  }) {
    final result = <StopDeparture>[];

    for (final schedule in schedules) {
      final departures = RingDepartures.from(
        weekdayTimes: schedule.weekday,
        weekendTimes: schedule.weekend,
        showWeekend: showWeekend,
        now: now,
      );

      // Tarife goruntuleme modunda "yarin" kavrami yok — gunun ilk kalkisi.
      final time = departures.isToday
          ? departures.tomorrowFirstTime
          : (departures.times.isEmpty ? null : departures.times.first);
      if (time == null) continue;

      result.add(
        StopDeparture(
          lineCode: schedule.lineCode,
          direction: _directionOf(schedule, routes),
          time: time,
          until: Duration.zero,
        ),
      );
    }

    result.sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      if (byTime != 0) return byTime;
      return a.lineCode.compareTo(b.lineCode);
    });
    return result;
  }
}
