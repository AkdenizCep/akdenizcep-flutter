import 'package:akdenizcep/features/ring/models/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dart'in yerlesik `toLowerCase()`/`toUpperCase()`'i Turkce bilmez:
/// 'I' -> 'i' (olmasi gereken 'ı'), 'İ' -> 'i' + birlesik nokta (bozuk),
/// 'i' -> 'I' (olmasi gereken 'İ'). Durak adlari dogrudan arayuzde
/// gorundugu icin bu kurallarin testi var.
void main() {
  group('turkishLower', () {
    test('noktali I kucukken noktayi kaybeder', () {
      expect(turkishLower('İSTANBUL'), 'istanbul');
    });

    test('noktasiz I kucukken noktasiz kalir', () {
      expect(turkishLower('ILIK'), 'ılık');
    });

    test('dart varsayilanindan farklidir', () {
      expect('I'.toLowerCase(), isNot(turkishLower('I')));
    });

    test('diger Turkce harfler bozulmaz', () {
      expect(turkishLower('ÜÇGEN ŞÖĞÜT'), 'üçgen şöğüt');
    });
  });

  group('turkishUpper', () {
    test('i buyurken nokta kazanir', () {
      expect(turkishUpper('iletişim'), 'İLETİŞİM');
    });

    test('noktasiz i buyurken noktasiz kalir', () {
      expect(turkishUpper('ılık'), 'ILIK');
    });
  });

  group('turkishTitleCase', () {
    test('tamami buyuk metni baslik bicimine cevirir', () {
      expect(turkishTitleCase('MERKEZİ YEMEKHANE'), 'Merkezi Yemekhane');
    });

    test('baglaclari kucuk birakir ama ilk kelimeyi birakmaz', () {
      expect(
        turkishTitleCase('İKTİSADİ VE İDARİ BİLİMLER FAKÜLTESİ'),
        'İktisadi ve İdari Bilimler Fakültesi',
      );
      expect(turkishTitleCase('VE SONRASI'), 'Ve Sonrası');
    });

    test('tireli kelimelerin iki parcasini da buyultur', () {
      expect(
        turkishTitleCase('GAZİ MUSTAFA KEMAL SPOR SALONU'),
        'Gazi Mustafa Kemal Spor Salonu',
      );
    });

    test('zaten duzgun yazilmis adi bozmaz', () {
      expect(
        turkishTitleCase('Uygulamalı Bilimler Fakültesi'),
        'Uygulamalı Bilimler Fakültesi',
      );
    });

    test('noktasiz I ile baslayan kelimeyi Turkce buyultur', () {
      // Veride "Iktisadi" yanlis yazilmis; duzeltilmis hali beklenir.
      expect(
        turkishTitleCase('Iktisadi ve Idari Bilimler Fakültesi'),
        'İktisadi ve İdari Bilimler Fakültesi',
      );
    });
  });

  group('parseStopName', () {
    test('kampus onekini kirpar', () {
      final result = parseStopName('AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE');

      expect(result.name, 'Merkezi Yemekhane');
      expect(result.side, isNull);
    });

    test('taraf ekini addan ayirir', () {
      final result = parseStopName('EDEBİYAT FAKÜLTESİ-1');

      expect(result.name, 'Edebiyat Fakültesi');
      expect(result.side, 1);
    });

    test('onek ve taraf ekini birlikte isler', () {
      final result = parseStopName('AKDENİZ ÜNİVERSİTESİ DOĞU KAPISI GİRİŞİ');

      expect(result.name, 'Doğu Kapısı Girişi');
    });

    test('ucuncu taraf da okunur', () {
      expect(parseStopName('HUKUK FAKÜLTESİ-3').side, 3);
    });

    test('addaki sayi taraf eki degilse korunur', () {
      // Tire yoksa sayi adin parcasidir.
      final result = parseStopName('TEKNOKENT 2 BİNASI');

      expect(result.name, 'Teknokent 2 Binası');
      expect(result.side, isNull);
    });
  });

  group('normalizeForSearch', () {
    test('aksanlari sadelestirir', () {
      expect(normalizeForSearch('Meltem Kapısı'), 'meltem kapisi');
      expect(normalizeForSearch('MÜHENDİSLİK'), 'muhendislik');
    });

    test('bosluklari kirpar', () {
      expect(normalizeForSearch('  Rektörlük  '), 'rektorluk');
    });
  });
}
