import '../../models/ring_schedule.dart';
import '../../models/ring_stop.dart';

/// Ring arayuzunun metin bicimlendirmeleri. Yalnizca sunum katmani —
/// hicbir hesaplama yapmaz.

/// "au102" -> "AÜ102"
String lineLabel(String lineCode) {
  final upper = lineCode.toUpperCase();
  return upper.startsWith('AU') ? 'AÜ${upper.substring(2)}' : upper;
}

String directionLabel(bool isReturn) => isReturn ? 'Dönüş' : 'Gidiş';

/// Guzergahin ilk ve son duragindan okunabilir yon metni uretir.
/// Durak verisi girilmemisse `null` doner — cagiran taraf
/// [directionLabel]'a dusmelidir.
({String from, String to})? routeEndpoints(
  RingSchedule? schedule,
  Map<String, RingStop> stopMap,
) {
  if (schedule == null || schedule.stops.length < 2) return null;

  final from = stopMap[schedule.stops.first]?.name;
  final to = stopMap[schedule.stops.last]?.name;
  if (from == null || to == null) return null;

  return (from: from, to: to);
}

/// Hattin varis yonunu kisa anlatan etiket: "Meltem Kapısı yönü".
/// Durak verisi yoksa "Gidiş" / "Dönüş"e duser.
String directionSummary(
  RingSchedule? schedule,
  Map<String, RingStop> stopMap,
) {
  final endpoints = routeEndpoints(schedule, stopMap);
  if (endpoints == null) return directionLabel(schedule?.isReturn ?? false);
  return '${endpoints.to} yönü';
}

/// Geri sayimi buyuk deger + kucuk birim olarak ikiye ayirir.
({String value, String unit}) countdownParts(Duration duration) {
  if (duration.inHours >= 1) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return (
      value: minutes == 0 ? '$hours sa' : '$hours sa $minutes dk',
      unit: 'sonra',
    );
  }
  if (duration.inMinutes >= 1) {
    return (value: '${duration.inMinutes}', unit: 'dakika');
  }
  return (value: '${duration.inSeconds.clamp(0, 59)}', unit: 'saniye');
}

/// Tek satirlik geri sayim metni — kartlarda ve listelerde.
String countdownText(Duration duration) {
  final parts = countdownParts(duration);
  return parts.unit == 'sonra'
      ? parts.value
      : '${parts.value} ${parts.unit == 'dakika' ? 'dk' : 'sn'}';
}

String distanceText(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Ortalama yurume hizi ~80 m/dk.
String walkingTimeText(double meters) {
  final minutes = (meters / 80).round();
  return minutes <= 1 ? '~1 dk yürüme' : '~$minutes dk yürüme';
}

String dayTypeLabel(bool showWeekend) =>
    showWeekend ? 'Hafta Sonu' : 'Hafta İçi';

String shortDayTypeLabel(bool showWeekend) =>
    showWeekend ? 'H.Sonu' : 'H.İçi';
