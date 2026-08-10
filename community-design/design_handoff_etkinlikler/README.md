# Handoff: Etkinlik Akışı, Etkinlik Detayı, Kulüp Profili, Etkinlik Oluşturma

Hedef proje: **AkdenizCep/akdenizcep-flutter** (Flutter + Riverpod + go_router + Firebase)

## Genel Bakış

Akdeniz Cep uygulamasının "Etkinlikler" bölümünün yeniden tasarımı. Dört ekran kapsanıyor:

| Tasarım id | Ekran | Flutter karşılığı (mevcut) |
| --- | --- | --- |
| **2a** | Etkinlik akışı (feed) | `lib/features/student_events/pages/student_events_page.dart` + `components/student_event_card.dart` |
| **1d** | Etkinlik detayı | `lib/features/student_events/pages/student_event_detail_page.dart` (ve `features/community/pages/event_detail_page.dart`) |
| **1e** | Kulüp profili | `lib/features/community/pages/club_detail_page.dart` |
| **1f** | Etkinlik oluşturma | `lib/features/student_events/pages/create_event_page.dart` |

Tasarımlar mevcut `lib/app/theme.dart` renk şeması ve tipografisiyle birebir uyumlu; `home_page.dart` içindeki yüzen alt navigasyon barı da aynen korunuyor.

## Tasarım Dosyaları Hakkında

Bu pakette bulunan `Etkinlikler.dc.html` bir **tasarım referansıdır** — HTML ile hazırlanmış, istenen görünümü ve davranışı gösteren bir prototiptir. Üretim kodu değildir ve doğrudan kopyalanmamalıdır.

Yapılacak iş: bu HTML tasarımları **hedef kod tabanının kendi ortamında yeniden oluşturmak** — yani Flutter widget'ları olarak, projedeki mevcut desenlerle (Riverpod provider'ları, go_router rotaları, `AppTheme` üzerinden `Theme.of(context).colorScheme` ve `textTheme`, `shared/components/app_card.dart`). HTML'deki hex/px değerleri, hangi tema token'ına denk geldiğini doğrulamak için verilmiştir; kodda mümkün olduğunca `colorScheme.*` ve `textTheme.*` kullanılmalıdır.

HTML dosyası bir "design canvas"tır: tüm seçenekler yan yana durur. Yalnızca `#2a`, `#1d`, `#1e`, `#1f` id'li kartlar geçerlidir. `#1a`, `#1b`, `#1c` kartları elenen alternatiflerdir — **uygulanmayacak**.

## Fidelity

**High-fidelity (hifi).** Renkler, tipografi, boşluklar ve etkileşimler nihai. Ekranlar piksel düzeyinde birebir uygulanmalı; stil için projedeki `AppTheme` kullanılmalı.

---

## Ekran 2a — Etkinlik Akışı

**Amaç:** Öğrenci kampüsteki tüm etkinlikleri tek akışta görür; kategoriye ve kaynağa (kulüp / öğrenci) göre süzer, karttan doğrudan katılır.

**Genel yerleşim** (yukarıdan aşağı, `Scaffold` + `SafeArea(bottom:false)` + `CustomScrollView`):

1. **Başlık bloğu** — padding `12,20,14,20`. Solda iki satır: `KATEGORİLER` (Roboto 800, 12px, `onSurfaceVariant #44474F`, letter-spacing .06em) ve `Etkinlikler` (Roboto 900, 28px, line-height 1.12, `onSurface #171A22`). Sağda arama tetikleyicisi: yükseklik 44, radius 22, `surface #fff`, 1px `outlineVariant #D6DCE8` kenarlık, içinde `Icons.search_rounded` (20px, `#44474F`) + "Ara" (Roboto 700, 13px).
2. **Kategori şeridi** — yatay kaydırmalı `ListView`, yükseklik ~95, padding `2,20,16,20`, öğeler arası 14px. Her öğe 68px genişlik: üstte 62×62 kutu radius 22, altında etiket (11px, seçili 800 / seçili değil 600).
   - Seçili değil: arka plan `kategoriRengi` %14 opaklık, 1px `#D6DCE8` kenarlık, ikon kategori renginde.
   - Seçili: arka plan kategori rengi dolu, ikon beyaz, dışında 3px beyaz + 5px kategori rengi halka (Flutter'da `Container` + `BoxShadow` yerine iç içe iki `Container` ile yapılabilir).
   - Kategoriler ve renk/ikonları: Hepsi `#135BEC` `Icons.apps_rounded` · Teknoloji `#135BEC` `Icons.memory_rounded` · Spor `#168A5B` `Icons.sports_soccer_rounded` · Sanat `#E8601C` `Icons.photo_camera_rounded` · Müzik `#7B3FF2` `Icons.music_note_rounded` · Akademik `#0F7B8A` `Icons.menu_book_rounded`.
3. **Kaynak filtresi** — yatay kaydırmalı chip satırı, padding `0,20,12,20`, aralık 8px. Chip: yükseklik 38, radius 19, ikon 17px + etiket Roboto 800/12px, iç boşluk yatay 14.
   - Seçili değil: `surface #fff`, 1px `#D6DCE8`, metin `#44474F`.
   - Seçili: arka plan `#171A22`, metin beyaz.
   - Seçenekler: "Tümü" (`Icons.apps_rounded`), "Kulüp etkinlikleri" (`Icons.groups_2_rounded`), "Öğrenci etkinlikleri" (`Icons.person_rounded`).
4. **Sonuç satırı** — padding `0,20,10,20`, solda aktif kategori adı (Roboto 800/15px, `#171A22`), sağda "N etkinlik" (Roboto 700/12px, `#44474F`).
5. **Kart listesi** — padding `0,20,140,20`, kartlar arası 18px. Alt padding 140, yüzen nav barının altında kalmaması için.

**Etkinlik kartı (2a):** `surface #fff`, 1px `#D6DCE8`, radius **20**, `clipBehavior: Clip.antiAlias`.

- **Görsel alanı** — yükseklik **230**, tam genişlik.
  - Arka plan: `imageUrl` varsa `CachedNetworkImage(fit: BoxFit.cover)`; yoksa fallback gradyanı `LinearGradient(topLeft→bottomRight, [kategoriRengi %95, kategoriRengi %48, primary #135BEC %52])` — bu, mevcut `student_event_card.dart` içindeki gradyan tarifiyle aynıdır.
  - Fallback üzerinde 45° çizgili doku (beyaz %9, 12px açık / 12px dolu) ve sağ altta taşan filigran ikon: 170px, beyaz %20, offset `right:-24, bottom:-30`.
  - Alt kenarda okunabilirlik gradyanı: yükseklik 110, `siyah %45 → şeffaf` (aşağıdan yukarı).
  - **Tarih rozeti** — sol üst `14,14`: beyaz, radius 16, padding `9,13`, gölge `0 6 16 rgba(0,0,0,.12)`, içinde `Icons.calendar_today_rounded` 15px `#135BEC` + tarih metni Roboto 900/12px `#135BEC`. Format: `DateFormat('d MMM, HH:mm','tr')` ve **büyük harfe çevrilmiş** (ör. "12 MAR, 18:00").
  - **Kaynak rozeti** — sağ üst `14,14`: radius 10, padding `5,10`, Roboto 800/10px, letter-spacing .04em. Kulüp → `primaryContainer #E8F0FF` üzerinde `onPrimaryContainer #082B76`, metin "KULÜP". Öğrenci → `secondaryContainer #FFE7D6` üzerinde `onSecondaryContainer #662500`, metin "ÖĞRENCİ".
- **Gövde** — padding `16,18,18,18`.
  - **Yazar satırı**: 46×46 logo kutusu radius 15 + 12px boşluk + iki satır metin + `Icons.more_horiz_rounded` (22px, `#44474F`).
    - Kulüp: logo varsa `CachedNetworkImage`; yoksa kategori rengi %14 arka plan, 1px `#D6DCE8`, ortada kategori ikonu 24px kategori renginde.
    - Öğrenci: dolu kategori rengi arka plan, ortada adın baş harfi (Roboto 900/18px, beyaz).
    - 1. satır: kulüp adı veya öğrenci adı — Roboto 800/15px, line-height 1.25, `#171A22`, tek satır ellipsis.
    - 2. satır: "Kulüp · 2 saat önce" / "Öğrenci paylaşımı · 5 saat önce" — Roboto 600/12px, `#44474F`. Göreli zaman mantığı mevcut `student_event_card.dart` içindeki `_relativeCreatedAt` ile aynı (Şimdi / N dk önce / N saat önce / N gün önce / `d MMMM`).
  - **Başlık**: üst boşluk 14, Roboto 900/21px, line-height 1.2, `#171A22`, 2 satır ellipsis.
  - **Konum**: üst boşluk 10, `Icons.location_on_rounded` 19px `#44474F` + 6px + metin Roboto 700/14px `#44474F`, tek satır ellipsis.
  - **Açıklama**: üst boşluk 12, Roboto 400/15px, line-height 1.45, `#171A22`, **maks. 2 satır** ellipsis.
  - **Ayırıcı**: 1px `#D6DCE8`, üst 16 / alt 14.
  - **Alt satır**: solda üst üste binen katılımcı avatarları (28×28, 2px beyaz kenarlık, -9px binme, baş harf Roboto 800/11px beyaz) + 18px sonra "+48 katılıyor" (Roboto 700/12px, `#44474F`). Sağda **Katıl** butonu: yükseklik 44, radius 16, yatay padding 22, Roboto 800/14px.
    - Katılmamış: dolu `primary #135BEC`, metin beyaz.
    - Katılmış: `#E8F0FF` arka plan, 1.5px `#135BEC` kenarlık, metin `#082B76`, etiket "Katılıyorsun".
- **FAB yok** — 2a'da etkinlik oluşturma girişi mevcut FAB yerine üst barda ya da nav barında konumlanabilir; mevcut `student_events_page.dart` FAB'ı korunacaksa `bottom: 120` padding'i aynen kalmalı.

**Alt navigasyon:** `home_page.dart` içindeki `_FloatingNavBar` aynen kullanılır — değişiklik yok.

---

## Ekran 1d — Etkinlik Detayı

**Amaç:** Etkinliğin tüm bilgisini görmek, katılmak, kulübü takip etmek, konumu haritada açmak, soru sormak.

Tek `CustomScrollView`; AppBar yok, görsel status bar'ın altına taşar (`extendBodyBehindAppBar` mantığı).

1. **Hero** — yükseklik **330**, tam genişlik. `imageUrl` varsa `BoxFit.cover`, yoksa 2a ile aynı gradyan + çizgili doku fallback'i. Alt 150px'te `siyah %55 → şeffaf` gradyan.
   - Üst kontroller (`top: 52`, yatay 20): geri butonu ve sağda kaydet + paylaş — üçü de 44×44 daire, `siyah %32` arka plan, 22px beyaz ikon (`arrow_back`, `bookmark`, `share`). Kaydet aktifken ikon dolu (`Icons.bookmark` ↔ `Icons.bookmark_border`).
   - Sol altta (`bottom: 44`, `left: 20`) etiket rozetleri: radius 12, padding `7,12`, `beyaz %92` arka plan, Roboto 900/11px. "TEKNOLOJİ" `#135BEC`, "ÜCRETSİZ" `#168A5B`.
2. **İçerik yaprağı** — hero'nun 26px üzerine biner (`margin-top: -26`), `scaffoldBackground #F7F8FB`, üst köşeler radius 26, padding `24,20,190,20` (alt padding sabit CTA barı için).
3. **Başlık** — Roboto 900/26px, line-height 1.16, `#171A22`.
4. **Tarih + Konum kartları** — üst boşluk 18, yan yana iki eşit kart, aralık 12. Her biri: `#fff`, 1px `#D6DCE8`, radius 16, padding 14. İçinde 18px ikon (`calendar_month_rounded` `#135BEC` / `location_on_rounded` `#E8601C`) + 6px + etiket (Roboto 800/11px `#44474F`, "TARİH" / "KONUM"); 8px altında değer (Roboto 800/15px `#171A22`) ve 2px altında alt değer (Roboto 600/13px `#44474F`).
5. **Kulüp kartı** — üst boşluk 14, `#fff`, 1px `#D6DCE8`, radius 16, padding 16. 52×52 logo (radius 18, `#E8F0FF`, 26px `#135BEC` ikon) + isim satırı (Roboto 800/16px + `Icons.verified_rounded` 16px `#135BEC`) + alt satır "1.248 takipçi · 32 etkinlik" (Roboto 600/12px `#44474F`) + **Takip Et** butonu (yükseklik 38, radius 19, padding yatay 16, Roboto 800/13px; takip edilmiyorsa dolu `#135BEC`/beyaz, ediliyorsa `#E8F0FF`/`#082B76` ve etiket "Takipte").
6. **Açıklama** — başlık Roboto 800/17px (üst boşluk 22), gövde Roboto 400/15px line-height 1.55.
7. **Katılımcılar** — başlık satırı: solda "Katılımcılar" (800/17px), sağda "Tümü" (700/13px `#135BEC`). Altında kart: 5 adet 36×36 avatar (-10px binme, 2px beyaz kenarlık), yanında "48 kişi katılıyor" (800/15px) ve "Kontenjan 60 · 12 yer kaldı" (600/12px `#44474F`). Sayı, kullanıcı katıldığında +1 artar.
8. **Konum** — başlık + kart (radius 16, 1px `#D6DCE8`). Üstte 140px `google_maps_flutter` haritası (prototipte gri ızgara placeholder), merkezde `#E8601C` pin. Altında padding `14,16`: "Mühendislik Fakültesi B Blok" (800/14px) + "Ana kapıdan 6 dk yürüme" (600/12px) ve sağda **Haritada aç** butonu (yükseklik 40, radius 14, 1px `#135BEC` kenarlıklı outline, metin `#135BEC` 800/13px) → `/map` rotasına gider.
9. **Sorular** — başlık satırı (sağda "N yorum"). Yorum kartları: `#fff`, 1px `#D6DCE8`, radius 16, padding `14,16`, 34×34 avatar + isim (800/14px) + göreli zaman (600/11px) + metin (400/14px line-height 1.45). Aralık 10.
10. **Yorum girişi** — `#fff`, 1px `#D6DCE8`, radius 24, sol padding 18, sağda 40×40 dolu `#135BEC` daire içinde `Icons.send_rounded` beyaz.
11. **Sabit alt CTA barı** — `left/right/bottom: 0`, padding `16,20,26,20`, arka plan `#F7F8FB %62 → şeffaf` gradyan. Solda fiyat bloğu ("Ücretsiz" 900/18px + "Kayıt gerekli" 600/12px), sağda tam genişlik **Katıl** butonu: yükseklik 56, radius 16, Roboto 800/16px, ikon 20px.
    - Katılmamış: dolu `#135BEC`, beyaz metin, `Icons.add_circle`.
    - Katılmış: `#E8F0FF`, 1.5px `#135BEC`, metin `#082B76`, `Icons.check_circle`, etiket "Katılıyorsun".

**Silme aksiyonu:** mevcut `student_event_detail_page.dart` içindeki "yalnızca `authorUid == currentUser.id` ise sil" davranışı korunur — üstteki `more`/silme girişine taşınmalı.

---

## Ekran 1e — Kulüp Profili

1. **Kapak** — yükseklik 200, hero ile aynı gradyan/görsel kuralı. Sol üstte (`top:52,left:20`) 44×44 geri butonu (`siyah %32`).
2. **Logo + Takip Et satırı** — kapağın 38px üzerine biner. Logo 84×84, radius 26, beyaz 3px kenarlık, gölge `0 6 18 rgba(0,0,0,.10)`, ortada 40px kategori ikonu. Yanında **Takip Et** butonu: `Expanded`, yükseklik 46, radius 23, Roboto 800/14px; takip edilmiyorsa dolu `#135BEC`, ediliyorsa beyaz zemin + 1.5px `#135BEC` kenarlık + "Takipte".
3. **İsim** — üst boşluk 16, Roboto 900/24px + 20px `Icons.verified_rounded` `#135BEC`.
4. **Etiketler** — üst boşluk 10, aralık 8: kategori chip'i (`#E8F0FF` / `#082B76`), kuruluş chip'i (`#F2F5FA` / `#44474F`); radius 12, padding `6,12`, Roboto 700/12px.
5. **Açıklama** — üst boşluk 14, Roboto 400/15px line-height 1.5.
6. **İstatistik kartları** — üst boşluk 18, üç eşit kart, aralık 10. Her biri `#fff` + 1px `#D6DCE8` + radius 16 + padding 14, ortalanmış: sayı Roboto 900/20px, altında etiket Roboto 700/11px `#44474F` (TAKİPÇİ / ETKİNLİK / YAKLAŞAN).
7. **Sekmeler** — üst boşluk 20, `#F2F5FA` kapsayıcı radius 26 padding 5, iki eşit sekme: yükseklik 40, radius 22, Roboto 800/13px. Aktif: beyaz zemin, `#135BEC` metin, gölge `0 2 6 rgba(0,0,0,.08)`. Pasif: şeffaf, `#44474F`. Etiketler: "Etkinlikler", "Hakkında".
8. **Etkinlik listesi** — kartlar arası 12. Her satır: `#fff`, 1px `#D6DCE8`, radius 16, padding 14. Solda 56×56 tarih kutusu (radius 16, kategori rengi %14 zemin, üstte gün Roboto 900/18px, 4px altında ay kısaltması Roboto 800/10px, ikisi de kategori renginde), ortada başlık (800/15px, 2 satır) + "18:00 · Mühendislik Fak. B Blok" (600/12px `#44474F`), sağda `Icons.chevron_right` 22px `#7A8494`.

---

## Ekran 1f — Etkinlik Oluşturma

Tam ekran form; üstte kapatma barı: `Icons.close` (24px) + ortalanmış "Etkinlik Oluştur" (Roboto 800/20px). Gövde padding `12,20,150,20`.

1. **KİMİN ADINA** — bölüm etiketi Roboto 800/12px `#44474F` letter-spacing .04em. Altında (10px) iki eşit seçenek, aralık 10: yükseklik 52, radius 16, ikon 20px + etiket Roboto 800/13px.
   - Seçili: `#E8F0FF` zemin, 1.5px `#135BEC`, metin `#082B76`.
   - Seçili değil: `#fff`, 1px `#D6DCE8`, metin `#44474F`.
   - Seçenekler: "Kendi adıma" (`Icons.person_rounded`), "<Kulüp adı>" (`Icons.groups_2_rounded`) — ikinci seçenek yalnızca kullanıcı bir kulübün yöneticisiyse (`club.adminUid == user.id`) görünür.
2. **Kapak görseli** — üst boşluk 22, yükseklik 150, radius 18, `#fff` zemin, **1.5px kesikli** `#B9C3D4` kenarlık. Ortada dikey: 30px `Icons.add_photo_alternate` `#135BEC`, "Kapak görseli ekle" (800/14px), "önerilen 1200 × 800 · opsiyonel" (monospace 11px `#7A8494`). Firebase Storage'a yüklenir (`shared/services/storage_service.dart`).
3. **Başlık alanı** — etiket 800/13px + 8px + `TextField`: yükseklik 56, radius 16, odaklıyken 1.4px `#135BEC` kenarlık (tema `inputDecorationTheme` ile aynı, yalnızca radius 16). Altta sağa yaslı karakter sayacı "24 / 80" (600/11px `#7A8494`), maks. 80 karakter.
4. **Tarih / Saat** — yan yana iki eşit alan, aralık 12. Her biri yükseklik 56, radius 16, `#FBFCFF` (`surfaceContainerLow`) zemin, 1px `#D6DCE8`; içinde 20px ikon (`calendar_month` / `schedule`) + değer (500/15px). Tıklayınca `showDatePicker` / `showTimePicker` (locale `tr`).
5. **Konum** — aynı alan stili; solda `Icons.location_on_rounded`, sağda "Haritadan seç" (800/12px `#135BEC`) → harita seçici.
6. **Kategori** — sarmalanan chip grubu, aralık 8. Chip: yükseklik 36, radius 18, Roboto 800/12px, padding yatay 15. Seçili: dolu `#135BEC` + beyaz metin. Pasif: `#F2F5FA` zemin, `#44474F` metin, kenarlıksız. Seçenekler: Teknoloji, Spor, Sanat, Müzik, Akademik, Sosyal.
7. **Açıklama** — çok satırlı alan, min yükseklik 110, radius 16, `#FBFCFF`, 1px `#D6DCE8`, padding `16,18`, ipucu metni 400/15px line-height 1.5 `#7A8494`: "Etkinliği birkaç cümleyle anlat: kimler katılabilir, ne getirmeli?"
8. **Kontenjan sınırı** — kart (`#fff`, 1px `#D6DCE8`, radius 16, padding 16): solda "Kontenjan sınırı" (800/14px) + "Katılımcı sayısını sınırla" (600/12px `#44474F`), sağda anahtar. Anahtar: 52×32 track radius 16 (`#135BEC` açık / `#D6DCE8` kapalı), 26×26 beyaz knob, 180ms geçiş. Açıkken altında sayı girişi gösterilir.
9. **Sabit alt bar** — padding `16,20,26,20`, `#F7F8FB %62 → şeffaf` gradyan. Tam genişlik buton: yükseklik 56, radius 16, dolu `#135BEC`, beyaz metin Roboto 800/16px, 22px `Icons.campaign_rounded` + "Etkinliği Paylaş". Zorunlu alanlar (başlık, tarih, konum) dolana kadar `disabled`.

---

## Etkileşimler ve Davranış

- **Kategori şeridi (2a):** tek seçim, anında filtreleme; kaynak filtresiyle **AND** ile birleşir. Seçim değişince liste 200ms fade/slide ile yenilenebilir.
- **Kaynak filtresi (2a):** "Tümü" varsayılan. "Kulüp etkinlikleri" → `ClubEvent` kaynağı; "Öğrenci etkinlikleri" → `StudentEvent` kaynağı. Feed iki koleksiyonun tarih sırasına göre birleşimidir.
- **Katıl (2a / 1d):** optimistic toggle — buton anında durum değiştirir, Firestore yazımı arkada. Hata olursa geri alınır ve `progress_snackbar.dart` ile uyarı gösterilir. Katılımcı sayısı ±1.
- **Takip Et (1d / 1e):** mevcut `communityService.followClub / unfollowClub` çağrıları; buton durumu `currentUser.followedClubs` üzerinden türetilir.
- **Kaydet (1d):** yerel + kullanıcı dokümanında saklanır; ikon dolu/boş geçişi.
- **Kart tıklaması (2a):** `context.go('/student-events/<id>')` — mevcut rota korunur; kulüp etkinlikleri için `/home/community/<clubId>/event/<eventId>`.
- **Yazar satırı tıklaması (2a):** kulüpse kulüp profiline (`/home/community/<clubId>`), öğrenciyse profil kartına gider.
- **Boş durum:** mevcut `_EmptyEventsView` korunur — 68px daire `primaryContainer` içinde `Icons.event_busy_rounded`, "Henüz etkinlik yok.", "Aramanı veya filtrelerini değiştirerek tekrar deneyebilirsin."
- **Yükleme:** mevcut `LoadingOverlay`; kart listesi için iskelet (shimmer) tercih edilebilir.
- **Hata:** mevcut `ErrorView(message: errorMessage(e))`.
- **Geçişler:** nav barı animasyonu ve gizlenme davranışı (`nav_visibility_provider.dart`) değişmez.

## State

| State | Nerede | Notlar |
| --- | --- | --- |
| `selectedCategory` | 2a | varsayılan "Hepsi" |
| `selectedSource` | 2a | all / club / student |
| `searchQuery` | 2a | mevcut arama mantığı korunur (başlık + konum + açıklama) |
| `joinedEventIds` | 2a, 1d | kullanıcı dokümanından; optimistic güncelleme |
| `isFollowing` | 1d, 1e | `currentUser.followedClubs` türevi |
| `isSaved` | 1d | kullanıcı dokümanı |
| `clubProfileTab` | 1e | events / about |
| `authorMode` | 1f | self / club |
| `hasQuota`, `quotaCount` | 1f | anahtar + sayı girişi |
| form alanları | 1f | title, date, time, location, category, description |

Veri kaynakları mevcut provider'lardan gelir: `studentEventsProvider`, `studentEventDetailProvider`, `clubsProvider`, `clubDetailProvider`, `clubEventsProvider`, `currentUserProvider`.

**Model eklemeleri gerekiyor:**
- `StudentEvent`: `category`, `imageUrl`, `attendeeIds` (veya `attendeeCount`), `capacity` alanları yok — eklenmeli. Şu an kategori, `student_event_card.dart` içinde başlık/açıklama anahtar kelimelerinden tahmin ediliyor (`_EventVisualStyle.fromEvent`); tasarım gerçek bir `category` alanı varsayıyor, anahtar kelime tahmini **fallback** olarak kalabilir.
- `ClubEvent`: `category`, `attendeeIds`, `capacity` eklenmeli.
- `Club`: `description`, `foundedYear`, `verified`, `coverUrl` eklenmeli (1e için).

## Design Tokens

Hepsi `lib/app/theme.dart` içinde mevcut — yeni token eklenmiyor.

**Renkler (light):**
`primary #135BEC` · `onPrimary #FFFFFF` · `primaryContainer #E8F0FF` · `onPrimaryContainer #082B76` · `secondary #E8601C` · `secondaryContainer #FFE7D6` · `onSecondaryContainer #662500` · `surface #FFFFFF` · `onSurface #171A22` · `surfaceContainerLow #FBFCFF` · `surfaceContainer #F2F5FA` · `surfaceContainerHigh #ECEFF6` · `surfaceContainerHighest #E5EAF3` · `outline #7A8494` · `outlineVariant #D6DCE8` · `error #BA1A1A` · `scaffoldBackground #F7F8FB` · `onSurfaceVariant ≈ #44474F` (seed'den türetilir).

**Kategori renkleri** (`_EventVisualStyle` ile aynı): Spor `#168A5B` · Sanat/Fotoğraf `#E8601C` · Teknoloji `#135BEC` · Müzik `#7B3FF2` · Akademik `#0F7B8A` (yeni) · Varsayılan `#135BEC`.

**Tipografi:** Roboto. Kullanılan ölçekler — 28/900, 26/900, 24/900, 21/900, 20/800, 18/900, 17/800, 16/800, 15/800, 15/400 (1.45–1.55), 14/800, 14/700, 13/800, 12/800, 12/700, 12/600, 11/800, 11/600, 10/800, monospace 10–11 (yalnızca placeholder etiketleri; üretimde kaldırılır).

**Radius:** 10 (rozet) · 12 (etiket chip) · 14 (küçük buton) · 15–16 (logo, buton, kart, alan) · 18–20 (görsel kart, kategori chip) · 22–26 (şerit kutusu, yaprak, sekme kapsayıcı) · 36 (nav bar) · 50% (avatar).

**Boşluk skalası:** 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 26 — yatay sayfa kenarı her yerde **20**.

**Gölgeler:** kart `0 6 16 rgba(0,0,0,.12)` (tarih rozeti) · logo `0 6 18 rgba(0,0,0,.10)` · nav bar `0 8 24 rgba(0,0,0,.05)` · aktif sekme `0 2 6 rgba(0,0,0,.08)`.

## Assets

- **İkonlar:** tamamı Material Symbols Rounded — Flutter tarafında `Icons.*_rounded` karşılıkları. Yeni asset gerekmiyor (`uses-material-design: true` zaten açık). Kullanılanlar: `apps`, `memory`, `sports_soccer`, `photo_camera`, `music_note`, `menu_book`, `directions_run`, `groups_2`, `person`, `search`, `calendar_today`, `calendar_month`, `schedule`, `location_on`, `more_horiz`, `bookmark`, `share`, `arrow_back`, `close`, `chevron_right`, `verified`, `send`, `add_circle`, `check_circle`, `add_photo_alternate`, `campaign`, `event_busy`, `home`, `restaurant`, `directions_bus`, `map`.
- **Görseller:** yok. Prototipteki çizgili gradyan alanlar gerçek etkinlik/kapak görselleri için placeholder'dır; `imageUrl` boşken **gradyan fallback** kalıcı davranıştır (tasarım kararı).
- **Font:** Roboto — Flutter varsayılanı, ek dosya gerekmez.

## Dosyalar

- `Etkinlikler.dc.html` — tüm tasarımlar. Tarayıcıda aç, `#2a`, `#1d`, `#1e`, `#1f` bölümlerine bak. Kartlar etkileşimlidir (sekmeler, filtreler, Katıl/Takip Et durumları tıklanabilir).
- `support.js` — HTML prototipin çalışması için gerekli runtime. Uygulanacak bir şey yok.
