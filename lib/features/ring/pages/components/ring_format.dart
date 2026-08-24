import '../../models/ring_stop.dart';
import '../../models/route_shape.dart';
import '../../models/turkish_text.dart';

/// Ring arayuzunun metin bicimlendirmeleri. Yalnizca sunum katmani —
/// hicbir hesaplama yapmaz.

/// "au102" -> "AÜ102"
String lineLabel(String lineCode) {
  final upper = lineCode.toUpperCase();
  return upper.startsWith('AU') ? 'AÜ${upper.substring(2)}' : upper;
}

String directionLabel(bool isReturn) => isReturn ? 'Dönüş' : 'Gidiş';

/// Hattin varis yonunu kisa anlatan etiket: "Meltem Kapısı yönü".
///
/// Kaynak `au_hatlar.json`'daki `label` ("AÜ102 · Meltem Kapısı yönü"); hat
/// kodu zaten ayri gosterildigi icin yalnizca yon parcasi alinir.
///
/// Eskiden bu metin `RingSchedule.stops` dizisinin ilk/son duragindan
/// turetiliyordu; o dizi uretimde hicbir hatta girilmedigi icin arayuz hep
/// "Gidiş"/"Dönüş"e dusuyordu.
String directionSummary(RouteShape? shape, {required bool isReturn}) {
  return labelTail(shape?.label) ?? directionLabel(isReturn);
}

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

/// Hattin **kalkis noktasi**: "Adli Tıp".
///
/// `headsign` ("ADLİ TIP → MELTEM KAPISI") ilk parcasindan okunur. Durak
/// listesinden okunamaz: AU102_0 ve AU103_0 icin `stopSequence` 2'den basliyor,
/// yani gercek kalkis duragi kampus disinda kaldigi icin veri setinde yok.
String? routeOrigin(RouteShape? shape) {
  if (shape == null) return null;

  final parts = shape.headsign.split('→');
  if (parts.isEmpty) return null;

  final origin = parts.first.trim();
  return origin.isEmpty ? null : turkishTitleCase(origin);
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
