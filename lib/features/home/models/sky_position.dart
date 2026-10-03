/// Güneşin ya da ayın gökyüzündeki yaklaşık konumu: ana sayfadaki ufuk
/// çizimini besler.
///
/// Gün doğumu ve batımı Antalya için (36.9 K, 30.7 D, UTC+3) her ayın 15'inde
/// NOAA güneş denklemleriyle hesaplanıp dakika olarak sabitlendi. Aradaki
/// günler iki komşu ay arasında doğrusal ara değerlenir. Hata birkaç dakikayı
/// geçmez; çizim için yeterli, takvim doğruluğu iddia edilmez.
library;

/// [progress] 0..1 arasındadır ve yay üzerindeki konumu verir. [isDay]
/// doğruysa 0 gün doğumu, 1 gün batımıdır. Yanlışsa 0 gün batımı, 1 ertesi
/// günün doğumudur.
typedef SkyPosition = ({bool isDay, double progress});

// Ocak'tan Aralık'a, gece yarısından itibaren dakika.
const _sunriseMinutes = [
  489,
  467,
  430,
  384,
  350,
  337,
  349,
  374,
  398,
  423,
  455,
  483,
];
const _sunsetMinutes = [
  1083,
  1116,
  1144,
  1171,
  1197,
  1217,
  1217,
  1191,
  1147,
  1102,
  1069,
  1062,
];

SkyPosition skyPositionAt(DateTime time) {
  final sunrise = _interpolate(_sunriseMinutes, time);
  final sunset = _interpolate(_sunsetMinutes, time);
  final now = time.hour * 60 + time.minute + time.second / 60;

  if (now >= sunrise && now < sunset) {
    return (isDay: true, progress: (now - sunrise) / (sunset - sunrise));
  }

  const dayMinutes = 24 * 60;
  final nightLength = dayMinutes - sunset + sunrise;
  final sinceSunset = now >= sunset ? now - sunset : now + dayMinutes - sunset;
  return (isDay: false, progress: (sinceSunset / nightLength).clamp(0.0, 1.0));
}

/// Tablodaki değerler ayın 15'ine denk gelir; [time] iki ay arasında kalırsa
/// komşuları arasında doğrusal ara değer döner.
double _interpolate(List<int> table, DateTime time) {
  final daysInMonth = DateTime(time.year, time.month + 1, 0).day;
  final position = (time.month - 1) + (time.day - 15) / daysInMonth;
  final base = position.floor();
  final fraction = position - base;
  final from = table[base % 12];
  final to = table[(base + 1) % 12];
  return from + (to - from) * fraction;
}
