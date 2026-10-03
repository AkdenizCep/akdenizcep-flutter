import '../../models/departure_point.dart';
import '../../models/ring_stop.dart';
import '../../models/route_shape.dart';

/// Ring arayuzunun metin bicimlendirmeleri. Yalnizca sunum katmani —
/// hicbir hesaplama yapmaz.

/// "au102" -> "AÜ102"
String lineLabel(String lineCode) {
  final upper = lineCode.toUpperCase();
  return upper.startsWith('AU') ? 'AÜ${upper.substring(2)}' : upper;
}

String directionLabel(bool isReturn) => isReturn ? 'Dönüş' : 'Gidiş';

/// "AÜ102 · Meltem Kapısı yönü" -> "Meltem Kapısı yönü".
String? labelTail(String? label) {
  if (label == null) return null;

  final parts = label.split('·');
  if (parts.length < 2) return null;

  final tail = parts.last.trim();
  return tail.isEmpty ? null : tail;
}

/// Yolun iki yakasindaki duraklari ayirt etmek icin kisa not.
///
/// "EDEBİYAT FAKÜLTESİ-1" ve "-2" ayni ada sahip iki ayri fiziksel duraktir;
/// kullanici dogru tarafta beklemeli. Ek yerine hangi yone hizmet ettigi
/// yazilir — "-1" kullaniciya bir sey anlatmaz.
///
/// Durak tek kayitliysa ya da birden fazla yone hizmet ediyorsa `null`.
String? stopSideNote(RingStop stop) {
  if (stop.side == null) return null;

  final tails = stop.servedBy
      .map((s) => labelTail(s.label))
      .whereType<String>()
      .toSet();
  return tails.length == 1 ? tails.first : null;
}

/// Hattin **kalkis noktasi**: "Adli Tıp". Turetme kurali
/// [DeparturePoints.nameOf]'te.
String? routeOrigin(RouteShape? shape) => DeparturePoints.nameOf(shape);

/// Hattin **varis noktasi**: "Meltem Kapısı".
String? routeDestination(RouteShape? shape) =>
    DeparturePoints.destinationOf(shape);

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

String shortDayTypeLabel(bool showWeekend) => showWeekend ? 'H.Sonu' : 'H.İçi';
