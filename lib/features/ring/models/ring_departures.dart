/// Bir hattin secili gun tipine ait kalkis saatlerinin hesaplanmis hali.
///
/// Saf Dart — Flutter veya Riverpod bilmez, boylece test edilebilir kalir.
///
/// ONEMLI: Buradaki her sey **kalkis** zamanidir. Universite durak bazli saat
/// yayinlamadigi icin herhangi bir durak icin varis zamani hesaplanamaz.
class RingDepartures {
  /// Secili gun tipinin tum kalkis saatleri, sirali ("HH:mm").
  final List<String> times;

  /// Secili gun tipi bugunun gun tipiyle ayni mi.
  /// `false` ise canli geri sayim anlamsizdir — arayuz yalnizca tarifeyi
  /// gostermelidir.
  final bool isToday;

  /// Bugunun siradaki kalkisi. `isToday` false ise veya bugun sefer
  /// kalmadiysa `null`.
  final String? nextTime;

  /// [nextTime]'a kalan sure.
  final Duration? untilNext;

  /// Bugunun son gecen kalkisi — ilerleme cubugu icin.
  final String? previousTime;

  /// Onceki kalkistan sonrakine gecen surenin orani (0..1).
  /// Gunun ilk kalkisindan once `null`.
  final double? progress;

  /// [nextTime] dahil, bugun kalan kalkislar.
  final List<String> upcoming;

  /// Bugun sefer kalmadiysa yarinin ilk kalkisi.
  /// Yarinin gun tipi bugunkinden farkli olabilir, bu hesaba katilir.
  final String? tomorrowFirstTime;

  const RingDepartures({
    required this.times,
    required this.isToday,
    this.nextTime,
    this.untilNext,
    this.previousTime,
    this.progress,
    this.upcoming = const [],
    this.tomorrowFirstTime,
  });

  static const empty = RingDepartures(times: [], isToday: false);

  factory RingDepartures.from({
    required List<String> weekdayTimes,
    required List<String> weekendTimes,
    required bool showWeekend,
    required DateTime now,
  }) {
    final times = [...(showWeekend ? weekendTimes : weekdayTimes)]..sort();
    final isToday = showWeekend == isWeekendDay(now);

    if (!isToday) {
      return RingDepartures(times: times, isToday: false, upcoming: times);
    }

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowTimes = [
      ...(isWeekendDay(tomorrow) ? weekendTimes : weekdayTimes),
    ]..sort();
    final tomorrowFirst = tomorrowTimes.isEmpty ? null : tomorrowTimes.first;

    final nextIndex = times.indexWhere((time) {
      final at = resolveTime(time, now);
      return at != null && !at.isBefore(now);
    });

    if (nextIndex == -1) {
      return RingDepartures(
        times: times,
        isToday: true,
        previousTime: times.isEmpty ? null : times.last,
        tomorrowFirstTime: tomorrowFirst,
      );
    }

    final nextTime = times[nextIndex];
    final nextAt = resolveTime(nextTime, now)!;
    final previousTime = nextIndex == 0 ? null : times[nextIndex - 1];

    double? progress;
    if (previousTime != null) {
      final previousAt = resolveTime(previousTime, now);
      if (previousAt != null) {
        final total = nextAt.difference(previousAt).inSeconds;
        if (total > 0) {
          final elapsed = now.difference(previousAt).inSeconds;
          progress = (elapsed / total).clamp(0.0, 1.0);
        }
      }
    }

    return RingDepartures(
      times: times,
      isToday: true,
      nextTime: nextTime,
      untilNext: nextAt.difference(now),
      previousTime: previousTime,
      progress: progress,
      upcoming: times.sublist(nextIndex),
      tomorrowFirstTime: tomorrowFirst,
    );
  }

  static bool isWeekendDay(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  /// "HH:mm" metnini [reference] gununde bir [DateTime]'a cevirir.
  /// Bicim bozuksa `null` doner.
  static DateTime? resolveTime(String time, DateTime reference) {
    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );
  }
}
