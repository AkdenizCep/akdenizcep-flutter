# Görev: Akdeniz Cep — Ulaşım (Ring) bölümünü yeni tasarıma göre uygula

Proje: **AkdenizCep/akdenizcep-flutter** (Flutter + Riverpod + go_router + Firebase RTDB + google_maps_flutter).
Tasarım referansı: `design_handoff_ulasim/README.md` (yazılı, bağlayıcı spec) ve `design_handoff_ulasim/Ulasim.dc.html` (hi-fi HTML mockup).

## Önce yap
1. `design_handoff_ulasim/README.md` dosyasını **tamamen** oku. Ölçüler, hiyerarşi ve davranışlar bağlayıcıdır.
2. `Ulasim.dc.html` kaynağını oku; yalnızca **`#5a`**, **`#2b`** ve **`#5b`** id'li ekranlar geçerlidir. Diğer tüm id'ler (1a–1c, 2a, 2c, 3a, 4a–4f, 5c, 5d) elenen alternatiflerdir — uygulanmaz.
3. Mevcut kodu tara ve **ne değişecek** listesini çıkar; onay al, sonra kodla:
   - `lib/features/ring/pages/ring_page.dart`, `ring_stops_page.dart`
   - `lib/features/ring/pages/components/` (next_departure_card, favorite_stops_row, ring_grid_actions, ring_search_bar, stop_detail_sheet, stops_map, stop_list_tile, ring_format)
   - `lib/features/ring/providers/ring_provider.dart`, `lib/features/ring/models/`
   - `lib/app/theme.dart` (yalnızca okumak için — token eklemiyoruz)
   - `lib/features/home/pages/home_page.dart` (yüzen nav bar — **değişmez**)

## Kurallar
- HTML üretim kodu değildir, kopyalanmaz. İş, tasarımı **Flutter widget'ları olarak yeniden kurmak**: Riverpod provider'ları, `Theme.of(context).colorScheme` / `textTheme`, mevcut `shared/components` parçaları.
- **Sabit hex/px renk yazma.** README'deki hex'ler yalnızca hangi tema token'ına denk geldiğini doğrulamak için. Yeni token eklenmiyor.
- Sayfa yatay kenarı 20; liste alt padding'i `130 + MediaQuery.padding.bottom`. İkonlar `Icons.*_rounded`. Yeni asset yok.
- Dil kuralı — kritik: üniversite durak bazlı saat yayınlamıyor. Gösterilen her saat **hattın kalkış noktasından ayrılma** zamanıdır. "varış / gelir / durağa ulaşır" gibi ifadeler yazma; "Saatler hattın kalkış noktasına aittir." notu her listede kalır.
- Mevcut yükleme / hata / boş durum görünümleri, konum izni akışı ve haritanın gecikmeli montajı (`_MapPlaceholder`) korunur — bunlar bilinçli çözümler.

## Kapsam — 3 ekran
1. **5a · Ulaşım ana ekranı** (`ring_page.dart`): hero kartın **içine** ÖNCEKİ / SONRAKİ / SON SEFER şeridi; arama çubuğunun **sağına yıldızlı favori duraklar butonu**; "SIK KULLANILAN DURAKLAR" → **YAKINDAKİ DURAKLAR** (mesafe + yürüme süresi + canlı geri sayım + hat rozetleri, en yakın durak vurgulu, sahte `_defaultStops` verisi silinir); alt ızgaranın sağ kartı "Yakındaki Duraklar" → **"Haritada Gör"** (`Icons.map_rounded`). Ana ekranda hatlar listesi ve duyuru şeridi **yok**.
2. **2b · Yakındaki duraklar** (`ring_stops_page.dart`): tam ekran harita + üstte yüzen geri/arama, sağda konum & katman butonları, altta **yatay kaydırmalı durak kartları** (kart ↔ pin senkronu, `selectedStopProvider`). Konum izni bandı, sol üstteki duruma çipine dönüşür.
3. **5b · Durak yaprağı** (`stop_detail_sheet.dart`): hat/yön grubu yerine **kronolojik tek liste** — solda dev dakika geri sayımı, sağda hat rozeti + yön + "HH:mm · sonrası HH:mm · HH:mm". Yeni saf-Dart yardımcı `StopDepartures.merge` yazılır ve **birim testi eklenir**.

## Çalışma şekli
Ekran ekran ilerle. Her ekran bitince `flutter analyze` çalıştır, kısaca ne yaptığını özetle, bir sonrakine geçmek için onay bekle. `StopDepartures.merge` için testi aynı adımda yaz. Emin olmadığın ölçü veya davranışı uydurma — sor.
