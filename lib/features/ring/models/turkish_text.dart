/// Turkce metin islemleri. Saf Dart — Flutter bilmez.
///
/// **Neden ozel bir kucultme:** Dart'in `toLowerCase()`'i Unicode varsayilanini
/// uygular ve Turkce'yi bilmez. `'I'.toLowerCase()` "i" verir (Turkce'de "ı"
/// olmali), `'İ'.toLowerCase()` ise "i" + birlesik nokta (U+0307) verir — ekranda
/// bozuk gorunur. Buyultmede de ayni sorun ters yonde: `'i'.toUpperCase()` "I"
/// verir, "İ" degil.
library;

const _lowerMap = {'I': 'ı', 'İ': 'i'};
const _upperMap = {'i': 'İ', 'ı': 'I'};

/// Turkce kucultme.
String turkishLower(String value) {
  final buffer = StringBuffer();
  for (final char in value.split('')) {
    buffer.write(_lowerMap[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

/// Turkce buyultme.
String turkishUpper(String value) {
  final buffer = StringBuffer();
  for (final char in value.split('')) {
    buffer.write(_upperMap[char] ?? char.toUpperCase());
  }
  return buffer.toString();
}

/// Baslik bicimi: her kelimenin ilk harfi buyuk, kalani kucuk.
///
/// Baglaclar kucuk kalir — "Iktisadi ve Idari" ornegindeki "ve" gibi. Ilk
/// kelime her zaman buyuk baslar.
const _lowercaseWords = {'ve', 'ile', 'için'};

/// Kaynak veride yanlis yazilmis kelimeler.
///
/// Bu bir bicimlendirme kurali **degil**, veri duzeltmesidir: GTFS adlarinin
/// cogu TAMAMI BUYUK gelir, elle yazilmis birkacinda ise Turkce "İ" yerine
/// ASCII "I" kullanilmis ("Iktisadi ve Idari Bilimler Fakültesi"). Hangi
/// kelimenin noktali oldugu genel bir kuralla bilinemeyecegi icin bilinen
/// kelimeler burada tek tek duzeltilir. Yenisi cikarsa bir satir eklenir.
const _misspellings = {'iktisadi': 'İktisadi', 'idari': 'İdari'};

String turkishTitleCase(String value) {
  final words = value.trim().split(RegExp(r'\s+'));
  final result = <String>[];

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;

    final lower = turkishLower(word);
    if (i > 0 && _lowercaseWords.contains(lower)) {
      result.add(lower);
      continue;
    }

    // "ıktisadi" (ASCII I'dan gelen) -> "İktisadi"
    final corrected = _misspellings[normalizeForSearch(lower)];
    result.add(corrected ?? _capitalizeWord(lower));
  }

  return result.join(' ');
}

/// Tireyle bolunmus parcalari da buyultur: "gazi-mustafa" -> "Gazi-Mustafa".
String _capitalizeWord(String lowerWord) {
  return lowerWord
      .split('-')
      .map((part) {
        if (part.isEmpty) return part;
        return turkishUpper(part[0]) + part.substring(1);
      })
      .join('-');
}

/// Aksansiz, kucuk harfli arama karsilastirmasi.
/// "Meltem Kapısı" sorgusu "meltem kapisi" ile de eslesir.
String normalizeForSearch(String value) {
  const map = {
    'ı': 'i',
    'İ': 'i',
    'ş': 's',
    'Ş': 's',
    'ğ': 'g',
    'Ğ': 'g',
    'ü': 'u',
    'Ü': 'u',
    'ö': 'o',
    'Ö': 'o',
    'ç': 'c',
    'Ç': 'c',
  };

  final buffer = StringBuffer();
  for (final char in turkishLower(value.trim()).split('')) {
    buffer.write(map[char] ?? char);
  }
  return buffer.toString();
}

/// GTFS durak adini arayuze uygun hale getirir.
///
/// Veri TAMAMI BUYUK HARF geliyor ve her ad "AKDENİZ ÜNİVERSİTESİ" onekini
/// tasiyor — hepsi ayni kampuste oldugu icin bu onek bilgi tasimaz, yalnizca
/// kart basliklarini tasirir.
///
/// Yolun iki yakasindaki duraklar "-1" / "-2" ekiyle ayriliyor
/// ("EDEBİYAT FAKÜLTESİ-1"). Ek addan ayrilir; hangi yone hizmet ettigi
/// bilgisi zaten `servedBy`'da oldugu icin ek arayuzde tekrar edilmez.
///
/// Donen kayit: gorunen ad + varsa taraf numarasi.
({String name, int? side}) parseStopName(String rawName) {
  var value = rawName.trim();

  const prefix = 'AKDENİZ ÜNİVERSİTESİ ';
  if (turkishUpper(value).startsWith(prefix)) {
    value = value.substring(prefix.length);
  }

  int? side;
  final match = RegExp(r'-(\d+)$').firstMatch(value);
  if (match != null) {
    side = int.tryParse(match.group(1)!);
    value = value.substring(0, match.start);
  }

  return (name: turkishTitleCase(value), side: side);
}
