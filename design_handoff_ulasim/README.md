# Handoff: Ulaşım (Ring) — ana ekran (9a) + tüm tarife yaprağı (9c)

Kaynak tasarım: `Ulasim.dc.html` (bu klasördeki kopya). **Yalnızca iki ekran geçerlidir:**

| Tasarım id | Ekran | Uygulanacak yer |
| --- | --- | --- |
| **9a** | Ulaşım ana ekranı | `lib/features/ring/pages/ring_page.dart` + components |
| **9c** | Tüm tarife — yaprak (bottom sheet) | `FullScheduleSheet`'in yerini alan yeni `TimetableSheet` |

`9b` (harita sayfası) dosyada durur ama **bu pakete dahil değildir** — "Haritada Gör" mevcut harita rotasına (`openStopsPage`) gider, o sayfaya dokunulmaz. Önceki paketteki 5a / 2b / 5b tasarımları **iptal**; eski README'yi kullanma.

Hedef: Flutter + Riverpod + go_router. Ölçüler 390×844 referansıyla, mantıksal px.

---

## Kavram: yön yok, **kalkış noktası** var

Kullanıcıya "hangi yöne gidiyor" gösterilmez; **otobüsün nereden kalktığı** gösterilir. İki kalkış noktası vardır: **Adli Tıp** ve **Meltem Kapısı**. **AÜ102 ve AÜ103 her zaman aynı anda** görünür. Ana ekranın ve tarife yaprağının omurgası budur.

Veri eşlemesi (**önce doğrula, uydurma**): her `RingSchedule` (hat + yön) için "kalkış noktası" = o tarifenin rotasındaki ilk durağın adı. Ana ekran, tarifeleri bu ada göre gruplar. Repoda bu bilgi türetilemiyorsa uygulamadan önce sor.

Hat renkleri (yalnızca iki hat var): **ilk hat → `colorScheme.primary`, ikinci hat → `colorScheme.onSurface`** (beyaz metin). İkiden fazla hat çıkarsa palet için sor.

## Ortak dil

Hiçbir yerde sabit hex yazma — `lib/app/theme.dart` şemasını kullan:

| Tasarımdaki değer | Tema karşılığı |
| --- | --- |
| `#135BEC` | `colorScheme.primary` |
| `#E8F0FF` | `primaryContainer` |
| `#171A22` | `onSurface` |
| `#44474F` | `onSurfaceVariant` |
| `#9AA1B0` / `#B4BAC6` | `onSurfaceVariant` @ ~0.7 / ~0.45 alfa |
| `#D6DCE8` / `#EDF1F7` | `outlineVariant` (kenarlık) / bölücü çizgi ~0.6 alfa |
| `#F2F5FA` / `#F7F8FB` | `surfaceContainerLow` / zemin |

Roboto; ağırlıklar 900 (saat, başlık), 800 (etiket), 700/600 (yardımcı). Sayfa yatay kenarı **20**, liste alt padding'i `130 + MediaQuery.padding.bottom`. İkonlar `Icons.*_rounded`. Yeni asset yok (harita önizlemesi hariç, aşağıya bak).

Dil kuralı: üniversite durak bazlı saat yayınlamıyor; her saat **kalkış noktasından ayrılma** saatidir. "varış / gelir / durağa ulaşır" yazma. "dk sonra" = kalkışa kalan süre. (Tasarımda not satırı yok; istersen tarife yaprağının altına "Saatler kalkış noktasına aittir." eklenebilir — sor.)

---

## 9a — Ulaşım ana ekranı

Sıra: **başlık → Yakındaki duraklar slider → Adli Tıp bloğu → Meltem Kapısı bloğu → alt buton satırı.** Eski hero kart (`NextDepartureCard`), hat pill'leri, arama çubuğu ve 2'li ızgara **kaldırılır**.

### Başlık
"AkdenizCep" 14/900 (`Cep` primary) + altında "Ulaşım" 23/900. Sağda iki **40×40 daire** buton (surface, 1px outlineVariant): `search_rounded` 21 (mevcut arama akışını açar) ve `star_rounded` 21 primary dolu (favori duraklar yaprağı, mevcut davranış). İçerik ilk öğeye 10 boşlukla başlar.

### Yakındaki duraklar (yatay slider)
- Başlık satırı (üst 10 / alt 6): "YAKINDAKİ DURAKLAR" 11.5/900 ls .09em · sağda "Tümü ›" 11.5/800 primary (mevcut duraklar sayfası).
- `ListView(scrollDirection: horizontal)`, kenarlara taşar (yatay padding 20, öğe aralığı 10).
- **Kart** 170 genişlik, radius 20, padding 12×14, surface, 1px outlineVariant. **En yakın durak** kartının kenarlığı 1px primary.
  1. Satır 1: `location_on_rounded` 17 (en yakında primary, diğerlerinde muted) + durak adı 14/800.
  2. Satır 2 (üst 3): `distanceText` + " · " + `walkingTimeText` — 11/600 onSurfaceVariant, tek satır.
  3. Satır 3 (üst 10): solda **en erken kalkışa kalan dk** — sayı 28/900 primary ls −.02em + " dk sonra" 12/800; sağda **o kalkışı yapan hattın rozeti** (22 yükseklik, radius 7, yatay 7, 10/900, hat rengi dolu / beyaz metin).
  4. Ayırıcı: üstte 1px çizgi, üst 10 boşluk + 9 padding. "HATLAR" 10/700 ls .06em muted, yanında **o duraktan geçen tüm hatların** küçük rozetleri (20 yükseklik, radius 6, yatay 7, 9.5/900, `surfaceContainerLow` zemin / onSurfaceVariant). Tek hat geçiyorsa tek rozet — boş/gri slot **yok**.
- Geri sayım: o durağın tüm tarifelerinin `RingDepartures.untilNext` değerlerinin en küçüğü; rozet o tarifenin hattı. Bugün sefer kalmadıysa sayı yerine "Bugün bitti" (rozet gizlenir).
- Kart dokunma: mevcut `StopDetailSheet` (bu pakette değişmez).
- Veri yoksa bölüm hiç çizilmez; sahte/varsayılan durak verisi eklenmez.

### Kalkış noktası blokları (×2)
Blok üst boşluğu 10. **Başlık satırı** (alt 5): `location_on_rounded` 19 primary dolu · nokta adı 16/900 · "kalkış noktası" 11.5/600 onSurfaceVariant · `Spacer` · (yalnızca kullanıcıya en yakın noktada) "SANA EN YAKIN" etiketi — 9/900 ls .06em, primary metin / `primaryContainer` zemin, radius 6, padding 3×6. Konum yoksa etiket yok.

**Kart:** surface, 1px outlineVariant, radius 20, içerik kırpılır. İçinde iki **hat satırı** (her satır padding 8×14, satırlar arası 1px üst çizgi):
- Üst satır: hat rozeti **53×26**, radius 8, 11.5/900 · `Expanded` **kalkış saati** 27/900 ls −.02em, tabular rakamlar · sağda **geri sayım hapı** (28 yükseklik, radius 14, yatay 11, 12.5/900): "N dk sonra". **Ekrandaki en yakın kalkış** (tüm satırlar içinde) `primary` dolu/beyaz metin; diğerleri `surfaceContainerLow` / onSurface.
- Alt satır (üst 5, sol padding 64, tek satır 11.5/600 onSurfaceVariant): `Önceki HH:mm` (muted .7) · `Sonra HH:mm` — değerler 800, onSurface. (Son sefer yalnızca 9c'de gösterilir.)
- Satırlar o noktanın hatlarını **kalkışa göre** sıralar. Değer yoksa "—" yaz, satırı gizleme.
- Bloklar sırası: kullanıcıya yakın olan üstte; konum yoksa sabit sıra.
- Bugün sefer kalmadıysa: saat yerine "Yarın HH:mm" (hap gizlenir), alt satır "Bugün bitti".
- Bu ekran her zaman **bugünün** tarifesini canlı gösterir (`nowProvider` saniyelik).

### Alt buton satırı
Üst 12, iki kart yan yana (aralık 10), **ikisi de 84 yükseklik, radius 24, `box-sizing: border-box`** (kenarlık yüksekliği bozmamalı — `SizedBox(height: 84)` içinde aynı yapıda `Container` + `BoxDecoration.border`).
- **Haritada Gör** (flex 1.6): primary zemin, gölge `0 10 24 primary@.3`. Arka planda **harita önizlemesi** (statik harita görüntüsü veya `liteModeEnabled` mini `GoogleMap` — seçenek için sor), üstünde soldan sağa gradyan: primary %0–45, primary@.5 %75, primary@.1 %100. Sol üst 30×30 radius 10 `white@.2` kutu + `map_rounded` 21 beyaz; sol alt "Haritada Gör" 17/900 beyaz; sağ üst 30×30 beyaz daire + `arrow_forward_rounded` 20 primary. Dokunma → `openStopsPage` (mevcut harita sayfası).
- **Tüm Tarife** (flex 1): surface, 1px outlineVariant. Aynı yerleşim: sol üst 30×30 radius 10 `primaryContainer` + `calendar_month_rounded` 21 primary; sol alt "Tüm Tarife" 17/900; sağ üst 30×30 daire `surfaceContainerLow` + `arrow_forward_rounded` 20 onSurfaceVariant. Dokunma → **9c yaprağı**.

---

## 9c — Tüm tarife yaprağı

Ana ekranın üstünde açılan **modal bottom sheet**. `showModalBottomSheet(isScrollControlled: true)`; yükseklik = ekran − ~78 (status bar altından başlar), üst köşe radius 30, zemin surface. Scrim `black@.5`. Açılırken `bottomNavVisibleProvider = false`, kapanınca `finally` ile true (mevcut sarmalayıcı). Aşağı çekince kapanır.

1. Tutma çizgisi 38×4, radius 2, `outlineVariant`, üst 10 (`showDragHandle` kullanılabilir).
2. Başlık satırı (padding 12×20): "Tüm Tarife" 21/900 · sağda 36×36 daire `surfaceContainerLow` + `close_rounded` 20.
3. Seçiciler (yatay padding 20, aralarında 8):
   - **Kalkış noktası** — 2 seçenekli segment (Adli Tıp / Meltem Kapısı), yükseklik 40, her seçeneğin solunda `location_on_rounded` 16 (seçili primary, değilse muted).
   - **Gün** — 2 seçenekli segment (Hafta içi / Hafta sonu), yükseklik 34. "Bugün" seçeneği **yok**; varsayılan seçim bugünün türüdür (`showWeekend`).
   - Segment: iç padding 3, radius 13, zemin `#EDF1F7` (surfaceContainerHighest), seçili parça surface zeminli, radius 10, gölge `0 1 4 black@.12`; metin 12.5/800 (seçili onSurface, değilse onSurfaceVariant).
4. **Sütun başlıkları** (üst 16, yatay 20): iki eşit sütun, aralık 10. Her başlık düz metin: hat adı 18/900 onSurface, altında **3px hat renginde çizgi**, padding 0×4×8. Başlık sabit kalır; liste altında kayar. (Kutu/dolgu/rozet **yok**.)
5. **Liste** — tek `SingleChildScrollView`, padding 0×20×34; içinde iki `Expanded` sütun (aralık 10). Saatler **saat dilimine göre gruplanır**: her grup `Column(gap 3)`, padding dikey 7, üstünde 1px outlineVariant çizgi. Sütunlar birbirinden bağımsızdır (satırların hizalı olması gerekmez — bilinçli).
   - **Hücre:** yükseklik 38, radius 11, yatay 11, **tam saat "HH:mm"** 17/800, tabular rakamlar.
   - **Geçmiş:** zemin yok, metin `onSurfaceVariant @ .45`.
   - **Normal:** `surfaceContainerLow` zemin, onSurface metin.
   - **Sıradaki (her sütunda ilk gelecek sefer, yalnızca bugünün türü görüntülenirken):** hat rengi dolu, beyaz metin 900, sağda "N dk" 11/800.
   - **Son sefer:** surface zemin + 1px onSurface kenarlık, sağda "SON" etiketi (9/900 ls .06em, beyaz metin / onSurface zemin, radius 5, padding 3×6).
   - Bugünün türünden farklı gün seçiliyse geçmiş/sıradaki durumları yok; tüm hücreler "Normal".
6. Açılışta (bugün görünümü) liste sıradaki sefere kaydırılır (öneri; ölçü tasarımda yok — sor).

---

## Yeni / değişen parçalar

| İş | Not |
| --- | --- |
| `NearbyStopsRow` | Yatay slider + `NearbyStopCard`. Eski `FavoriteStopsRow` ve `_defaultStops` silinir. |
| `DeparturePointBlock` + `LineDepartureRow` | Kalkış noktası başına kart; `RingDepartures`'tan `previousTime`, `nextTime`, `upcoming[1]` okunur. |
| `RingActionsRow` | "Haritada Gör" + "Tüm Tarife" kartları. `RingGridActions` ve `NextDepartureCard` kullanımdan kalkar. |
| `TimetableSheet` | 9c. `FullScheduleSheet`'in yerini alır. |
| Kalkış noktası türetme | Tarife → ilk durak adı. Saf Dart, testli. |
| `RingDepartures` / model / servis | Değişmez. Firestore/RTDB şeması değişmez. |

## Korunacak davranışlar

- Konum izni akışı (`userPositionProvider.request()`, kalıcı ret → snackbar + "Ayarlar").
- Yükleme / hata / boş durum görünümleri.
- `bottomNavVisibleProvider` yaprak açılışında false, kapanışta true (`finally`).
- `ring_format.dart` yardımcıları (`distanceText`, `walkingTimeText`, `countdownText`, `lineLabel`) — yeni biçimlendirme yazmadan önce buraya bak.
- Harita platform view'inin gecikmeli montajı (`_MapPlaceholder`) — "Haritada Gör" önizlemesi gerçek `GoogleMap` kullanırsa aynı kural geçerli.
