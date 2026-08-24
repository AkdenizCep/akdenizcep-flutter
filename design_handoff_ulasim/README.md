# Handoff: Ulaşım (Ring) — ana ekran, yakındaki duraklar haritası, durak yaprağı

Kaynak tasarım dosyası: `Ulasim.dc.html` (bu klasördeki kopya). Bu paketin kapsadığı üç ekran:

| Tasarım id | Ekran | Uygulanacak dosya |
| --- | --- | --- |
| **5a** | Ulaşım ana ekranı (revize) | `lib/features/ring/pages/ring_page.dart` + components |
| **2b** | Yakındaki duraklar — tam ekran harita | `lib/features/ring/pages/ring_stops_page.dart`, `components/stops_map.dart` |
| **5b** | Durak detayı — yarım sayfa yaprak | `lib/features/ring/pages/components/stop_detail_sheet.dart` |

Diğer id'ler (1a–1c, 2a, 2c, 3a, 4a–4f, 5c, 5d) elenen alternatiflerdir — **uygulanmayacak**.

Hedef: Flutter + Riverpod + go_router, Google Maps (`google_maps_flutter`), Firebase RTDB.
Ölçüler 390×844 (iPhone 13/14) referansıyla verilmiştir; hepsi mantıksal px.

---

## Ortak dil

Renkler `lib/app/theme.dart` içindeki mevcut şemadan gelir — **hiçbir yerde sabit hex yazma**:

| Tasarımdaki değer | Tema karşılığı |
| --- | --- |
| `#135BEC` | `colorScheme.primary` |
| `#E8F0FF` | `colorScheme.primaryContainer` |
| `#082B76` | `colorScheme.onPrimaryContainer` |
| `#171A22` | `colorScheme.onSurface` |
| `#44474F` | `colorScheme.onSurfaceVariant` |
| `#9AA1B0` | `onSurfaceVariant` @ ~0.7 alfa |
| `#D6DCE8` / `#EDF1F7` | `colorScheme.outlineVariant` (kenarlıklarda ~0.6 alfa) |
| `#F2F5FA` / `#F7F8FB` | `surfaceContainerLow` / `surfaceContainerHighest` |

Tipografi: Roboto. Kullanılan ağırlıklar 900 (başlık/saat), 800 (etiket, buton), 700/600 (yardımcı metin), 500 (placeholder).
Geometri: sayfa yatay kenarı **20**; hero kart radius **24–26**; kart radius **20–22**; chip/rozet radius **8–9**; dokunma hedefleri ≥ 44.
Liste alt padding: `130 + MediaQuery.padding.bottom` (yüzen nav barın altında kalmasın) — mevcut değer korunur.
İkonlar: Material Symbols Rounded → `Icons.*_rounded`. Yeni asset yok.

Dil kuralı (mevcut kodun yorumundaki uyarı geçerli): üniversite durak bazlı saat yayınlamıyor. Gösterilen her saat **hattın kalkış noktasından ayrılma** zamanıdır. "varış", "gelir", "otobüs burada olur" gibi ifadeler kullanılmaz; her listenin altında `Saatler hattın kalkış noktasına aittir.` notu kalır.

---

## Ekran 5a — Ulaşım ana ekranı (revize)

Mevcut `_RingContent` sırası: header → hero → arama → sık kullanılan duraklar → 2'li ızgara.
**Yeni sıra:**

1. `RingHeader` (değişmez): "AkdenizCep" üst satırı + "Ulaşım" başlığı + sağda 40×40 avatar.
2. **`NextDepartureCard` (hero)** — mevcut kart korunur, **kartın içine yeni bir alt şerit eklenir**:
   - Kartın alt kenarında `1px` `Colors.white @ 0.22` üst çizgi, üstünde 14 boşluk, üstündeki içerikten 16 sonra.
   - Şerit üç eşit `Expanded`: **ÖNCEKİ**, **SONRAKİ**, **SON SEFER**.
   - Etiketler: Roboto 700 / 9.5px / letterSpacing .08em / `white @ .70`.
   - Değerler: Roboto 900 / 15px. ÖNCEKİ değeri `white @ .65` (geçmiş olduğu için soluk), diğer ikisi tam beyaz.
   - Veri: `RingDepartures` üzerinden — `previousTime`, `upcoming` listesinin 2. elemanı (yani `nextTime`'dan sonraki kalkış), `times.last`. Değer yoksa `—` yazılır, satır gizlenmez.
   - Bu şerit **yalnızca `departures.isToday`** iken canlı; hafta sonu/hafta içi tarifesi görüntüleniyorsa (`isToday == false`) ÖNCEKİ yerine ilk kalkış gösterilir ve alt açıklama satırı "Tarife görüntülüyorsun" der.
3. **Arama satırı** — `RingSearchBar` (mevcut bileşen, radius 28 → tasarımdaki 20'ye çekilir; hint metni aynı) **+ sağında 50×50 favori butonu**:
   - Satır: `Row(children: [Expanded(RingSearchBar), SizedBox(width:10), _FavoriteStopsButton()])`.
   - Buton: 50×50, radius 20, `surface` zemin, `outlineVariant` 1px kenarlık, ortada 22px `Icons.star_rounded` `colorScheme.primary`.
   - Davranış: favori duraklar yaprağını açar (`showModalBottomSheet`, `StopDetailSheet` ile aynı nav-gizleme sarmalayıcısı). Favori yoksa yaprakta "Henüz favori durağın yok — bir durağın yanındaki yıldıza dokun." boş durumu.
4. **YAKINDAKİ DURAKLAR** başlığı (Roboto 900 / 11.5 / ls .09em / `onSurface`) + sağda "Tümü ›" (Roboto 800 / 11.5 / `primary`, dokunma → duraklar sayfası).
   - Mevcut `FavoriteStopsRow` bu bölümün yerini alır ve **`NearbyStopsRow`** olarak yeniden adlandırılır. "SIK KULLANILAN DURAKLAR" başlığı ve `_defaultStops` sahte veri **kaldırılır** (veri yoksa bölüm hiç çizilmez).
   - Kart: 176 genişlik, radius 20, `surface`, `outlineVariant` kenarlık. İçerik sırası:
     - Satır 1: 18px `Icons.location_on_rounded` (en yakın durakta `primary`, diğerlerinde `onSurfaceVariant @ .7`) + durak adı (Roboto 800 / 14).
     - Satır 2: `distanceText` + " · " + `walkingTimeText` (Roboto 600 / 11.5 / `onSurfaceVariant`).
     - Satır 3: geri sayım — sayı Roboto 900 / 22 / `primary`, yanında "dk sonra" Roboto 700 / 11.5.
     - Satır 4: o duraktan geçen hat rozetleri (yükseklik 22, radius 7, `surfaceContainerLow`, Roboto 900 / 10).
   - **En yakın durak** kartı `primary` renkli 1px kenarlıkla işaretlenir.
   - Geri sayım: o durağın `schedules` listesindeki tüm tarifelerin `RingDepartures.untilNext` değerlerinin **en küçüğü**. Bugün sefer kalmadıysa sayı yerine "Bugün bitti", altında yarının ilk kalkışı.
5. **2'li ızgara** (`RingGridActions`) — kart yüksekliği 150 → tasarımda içerik kadar (ikon 40×40 radius 14 + başlık, sol hizalı, padding 16, radius 20):
   - Sol: **Tüm Tarife**, `Icons.calendar_month_rounded` — mevcut `FullScheduleSheet`.
   - Sağ: **Haritada Gör**, `Icons.map_rounded` — `openStopsPage`. (Eski başlık "Yakındaki\nDuraklar" ve `location_on` ikonu değişti; artık yakındaki duraklar yukarıdaki şeritte.)

**Kaldırılanlar:** hiçbir duyuru/gecikme şeridi eklenmez (tasarımda denendi, elendi); ana ekranda **hatlar listesi yok** — hat seçimi yalnızca hero kartın pill'leriyle yapılır.

---

## Ekran 2b — Yakındaki duraklar (tam ekran harita)

Mevcut `RingStopsPage` (240px harita + altında liste) **tam ekran haritaya** dönüşür.

- `AppBar` kaldırılır; `Scaffold(extendBodyBehindAppBar)` yerine `Stack`:
  1. `StopsMap` tüm alanı kaplar (`Positioned.fill`). Gecikmeli montaj + `_MapPlaceholder` davranışı **aynen korunur**.
  2. Üstte okunabilirlik için ince beyaz→şeffaf gradyan (üst %22), altta şeffaf→`black @ .16`.
  3. Üst satır (status bar altında, `top: 52`, yatay 20): 44×44 dairesel beyaz geri butonu (`Icons.arrow_back_rounded`, gölge `0 3 12 black@.14`) + `Expanded` beyaz arama alanı (yükseklik 44, radius 22, `Icons.search_rounded` + "Durak ara").
  4. Sağ kenarda dikey buton yığını (`top: 112`, 42×42, radius 15, beyaz, gölgeli): `Icons.my_location_rounded` (`primary`) ve `Icons.layers_rounded` (`onSurfaceVariant`).
  5. Sol üstte durum çipi: yükseklik 32, radius 16, `onSurface @ .88` zemin, `Icons.place_rounded` 15px + "N durak yakında" (Roboto 800 / 11.5, beyaz). Konum izni yoksa metin "Konumunu aç" olur ve dokunma `_requestLocation`'ı çağırır — **mevcut `_EnableLocationBanner` bu çipin yerini alır** (izin akışı, snackbar ve "Ayarlar" aksiyonu aynı kalır).
  6. Altta yatay kaydırmalı durak kartları (`bottom: 104`, yatay padding 20, aralık 12): kart 274 genişlik, radius 24, beyaz, gölge `0 8 28 rgba(16,24,40,.20)`, `PageView`/`ListView` + `snap`.
     - Kart içeriği: 40×40 radius 14 pin kutusu (seçili kart `primary` zemin + beyaz ikon; diğerleri `primaryContainer` + `primary` ikon) · durak adı Roboto 900 / 16 · `distanceText` + `walkingTimeText` · sağda favori yıldızı (dolu/boş) · hat rozetleri (`primaryContainer`, Roboto 900 / 11) · ayırıcı üstünde sıradaki kalkış satırı ("Sıradaki kalkış **08:51** · 3 dk" / bugün bittiyse "Bugün bitti · yarın ilk kalkış 06:31") · altta 42 yükseklikli `primary` "Hatları gör" butonu + 42×42 `surfaceContainerLow` `Icons.directions_walk_rounded` butonu.
  7. Yüzen alt nav bar görünür kalır (`bottomNavVisibleProvider` **true**) — kart şeridi onun üstünde durur.
- **Kart ↔ pin senkronu:** kaydırma seçili kartı değiştirir → `GoogleMapController.animateCamera` o durağa gider ve marker vurgulanır; haritada bir pine dokunmak ilgili kartı öne getirir. Seçili durak için ayrı bir `StateProvider<String?> selectedStopProvider` eklenir.
- "Hatları gör" → **5b yaprağı** (`StopDetailSheet`). Yaprak açılırken `bottomNavVisibleProvider = false` (mevcut davranış).
- Konum yoksa: harita kampüs merkezine odaklanır, mesafe/yürüme satırları gizlenir, kartlar güzergâh sırasına göre dizilir (`nearbyStopsProvider` bunu zaten yapıyor).
- `_LoadingView`, `_StopsErrorView`, `_NoStopsView` korunur; artık haritanın üstünde ortalanmış beyaz bir kart olarak gösterilir.

---

## Ekran 5b — Durak detayı (yarım sayfa yaprak)

`StopDetailSheet` yeniden düzenlenir. Yaprak yüksekliği içeriğe göre ~%60 ekran (`isScrollControlled: true`, `DraggableScrollableSheet` gerekmez; `showDragHandle: true` korunur), üst köşe radius 30.

**Başlık bloğu** (padding 20, alt boşluk 14): 24px `Icons.place_rounded` `primary` + durak adı (Roboto 900 / 20) + altında `distanceText` + " · " + `walkingTimeText` (Roboto 600 / 11.5); sağda 40×40 radius 14 `surfaceContainerLow` favori yıldızı (dolu/boş, dokunmayla değişir).

**"SIRADAKİ KALKIŞLAR"** (Roboto 900 / 11.5 / ls .09em) — mevcut hat kartları yerine **kronolojik tek liste**:

- Bu duraktan geçen **tüm tarifelerin** kalkışları tek listede birleşir ve **zamana göre** sıralanır (hat/yön grubu yok). Yeni saf-Dart yardımcı: `StopDepartures.merge({required List<RingSchedule> schedules, required Map<String,RingStop> stopMap, required bool showWeekend, required DateTime now})` → `List<StopDeparture>` (`lineCode`, `direction`, `time`, `until`, `nextTwo`). `RingDepartures.from` her tarife için ayrı çağrılır, sonuçlar düzleştirilir. `ring_departures.dart` gibi Flutter'dan bağımsız kalmalı ve testi yazılmalı.
- Satır (yükseklik ~ 15+15 padding, aralarında 1px `outlineVariant` üst çizgi):
  - Sol: 58 genişlikte ortalanmış geri sayım — sayı Roboto 900 / 26, altında birim "DAKİKA" Roboto 800 / 9.5. **İlk satır** `primary` renkli, diğerleri `onSurface` + birim `onSurfaceVariant @ .7`. Süre 1 saati aşarsa `countdownParts` zaten "1 sa 5 dk" veriyor → sayı alanına o metin (Roboto 900 / 18) ve birim "SONRA".
  - Sağ: hat rozeti (ilk satırda `primary` zemin/beyaz metin, diğerlerinde `primaryContainer`/`onPrimaryContainer`; yükseklik 23, radius 8, Roboto 900 / 10.5) + yön metni `directionSummary` (Roboto 800 / 14); altında "HH:mm · sonrası HH:mm · HH:mm" (Roboto 600 / 11.5 / `onSurfaceVariant`).
- Bugün sefer kalmadıysa satır listesi yerine: "Bugünün seferleri bitti" başlığı + her hat için "Yarın ilk kalkış HH:mm" satırı (aynı satır düzeni, geri sayım alanında saat).
- Hat bilgisi girilmemişse mevcut metin korunur: "Bu duraktan geçen hat bilgisi girilmemiş."
- En altta 16px `Icons.info_outline_rounded` + "Saatler hattın kalkış noktasına aittir."
- Geri sayımlar `nowProvider` (saniyelik ticker) ile canlıdır; yaprak açıkken her saniye güncellenir.

---

## Yeni state / model işleri

| İş | Not |
| --- | --- |
| `favoriteStopIdsProvider` | Favori durak id'leri. Kalıcılık `SharedPreferences` (yerel) — kullanıcıya bağlı senkron gerekiyorsa önce sor. Yıldız butonları bunu okur/yazar. |
| `selectedStopProvider` | 2b'deki kart↔pin senkronu için seçili durak id'si. |
| `StopDepartures.merge` | 5b'nin kronolojik listesi. Saf Dart, testli. |
| `nearbyStopsProvider` | Değişmez. Kart geri sayımı için `schedules` üzerinden en yakın `untilNext` hesaplanır (türetilmiş küçük bir provider yeterli). |
| `RingDepartures` | Değişmez — `previousTime`, `upcoming`, `times.last` alanları 5a şeridi için yeterli. |

Firestore/RTDB şeması değişmez. `RingStop`, `RingSchedule` alanlarına dokunulmaz.

---

## Korunacak davranışlar

- Harita platform view'inin **geçiş animasyonu bitince** monte edilmesi ve `_MapPlaceholder` (bu, "buton tepki vermedi" hatasının çözümüydü — kaldırılmaz).
- Konum izni akışı: `userPositionProvider.request()`, kalıcı ret → snackbar + "Ayarlar".
- `bottomNavVisibleProvider` yaprak açılışlarında false, kapanışta true (`finally` bloğu).
- Yükleme / hata / boş durum görünümleri.
- `ring_format.dart` yardımcıları (`lineLabel`, `directionSummary`, `countdownText`, `distanceText`, `walkingTimeText`) — yeni bir biçimlendirme yazmadan önce buraya bak.
