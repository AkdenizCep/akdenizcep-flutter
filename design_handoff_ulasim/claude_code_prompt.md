# Görev: Akdeniz Cep — Ulaşım bölümünü yeni tasarıma göre uygula (9a ana ekran + 9c tarife yaprağı)

Proje: **AkdenizCep/akdenizcep-flutter** (Flutter + Riverpod + go_router + Firebase RTDB + google_maps_flutter).
Tasarım referansı: `design_handoff_ulasim/README.md` (yazılı, bağlayıcı spec) ve `design_handoff_ulasim/Ulasim.dc.html` (hi-fi HTML mockup).

## Önce yap
1. `README.md` dosyasını **tamamen** oku. Ölçüler, hiyerarşi ve davranışlar bağlayıcıdır.
2. `Ulasim.dc.html` içinde yalnızca **`#9a`** ve **`#9c`** geçerlidir. `#9b` (harita sayfası) kapsam dışıdır — dokunma; "Haritada Gör" mevcut harita rotasına gider.
3. Mevcut kodu tara ve **ne değişecek** listesini çıkar; onay al, sonra kodla:
   - `lib/features/ring/pages/ring_page.dart`
   - `lib/features/ring/pages/components/` (next_departure_card, favorite_stops_row, ring_grid_actions, ring_search_bar, full_schedule_sheet, stop_detail_sheet, ring_format)
   - `lib/features/ring/providers/ring_provider.dart`, `lib/features/ring/models/`, `services/ring_service.dart`
   - `lib/app/theme.dart` (yalnızca oku — token eklemiyoruz)
   - `lib/features/home/pages/home_page.dart` (yüzen nav bar — **değişmez**)

## Kurallar
- HTML üretim kodu değildir, kopyalanmaz. İş, tasarımı **Flutter widget'ları olarak yeniden kurmak**: Riverpod provider'ları, `Theme.of(context).colorScheme` / `textTheme`.
- **Sabit hex/px renk yazma.** README'deki hex'ler yalnızca hangi tema token'ına denk geldiğini doğrulamak içindir. Yeni token yok.
- Sayfa yatay kenarı 20; liste alt padding'i `130 + MediaQuery.padding.bottom`. İkonlar `Icons.*_rounded`.
- **Kavram: yön yok, kalkış noktası var** (Adli Tıp / Meltem Kapısı). AÜ102 ve AÜ103 her zaman aynı anda görünür. "Kalkış noktası" verisini tarifelerden nasıl türeteceğini README'deki kurala göre **önce doğrula**; türetilemiyorsa uygulamadan önce sor.
- Dil kuralı — kritik: üniversite durak bazlı saat yayınlamıyor. Her saat **kalkış noktasından ayrılma** saatidir. "varış / gelir / durağa ulaşır" yazma.
- Yükleme / hata / boş durumlar, konum izni akışı, `bottomNavVisibleProvider` (yaprakta false, `finally` ile true) ve `_MapPlaceholder` gecikmeli montajı korunur.
- İki buton kartı (Haritada Gör / Tüm Tarife) **birebir aynı yükseklikte** olmalı: kenarlık yüksekliği bozmayacak şekilde kur.

## Kapsam — 2 ekran
1. **9a · Ana ekran:** eski hero kart / hat pill'leri / arama çubuğu / 2'li ızgara kalkar. Yeni sıra: başlık (arama + favori daire butonları) → **Yakındaki duraklar yatay slider** (kart: ad, mesafe·yürüme, en erken kalkışa dk + o hattın rozeti, "HATLAR" satırı) → **Adli Tıp** ve **Meltem Kapısı** blokları (her birinde iki hat satırı: rozet, büyük kalkış saati, "N dk sonra" hapı, önceki·sonra) → **Haritada Gör** (büyük, harita önizlemeli) + **Tüm Tarife** kartları (ikisi 84 yükseklik).
2. **9c · Tüm tarife yaprağı:** modal bottom sheet; kalkış noktası + hafta içi/hafta sonu segmentleri (Bugün seçeneği yok); iki hat **yan yana sütun**, düz başlık (hat adı + 3px renkli çizgi); tam saat hücreleri, saat dilimine göre gruplu; geçmiş soluk, sıradaki dolu, son sefer çerçeveli + "SON".

## Çalışma şekli
Ekran ekran ilerle (önce 9a, sonra 9c). Her ekran bitince `flutter analyze` çalıştır, kısaca ne yaptığını özetle, onay bekle. Kalkış noktası türetme yardımcısı için birim testi aynı adımda yaz. Emin olmadığın ölçü, veri eşlemesi veya davranışı (harita önizleme yöntemi, yaprak açılışında kaydırma, ikiden fazla hat) uydurma — sor.
