---
title: home
type: feature
updated: 2026-10-03
status: stale
sources:
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/home/services/home_service.dart
    sha: 44ab794
  - path: lib/app/router.dart
    sha: 089b8e8
---

# home

## Sorumluluk

İki iş birden yapıyor ve bu ayrım önemli:

1. **Kabuk (`HomePage`).** `StatefulShellRoute` gövdesi — beş sekmeli alt navigasyonu barındırır. Diğer tüm feature'lar bunun içinde yaşar.
2. **İçerik (`HomeContentPage`).** Karşılama metni, duyuru slider'ı, kullanıcının özelleştirebildiği hızlı erişim ızgarası ve yaklaşan etkinlik kartları.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/announcements]] | okur (`createdAt` azalan) |
| [[wiki/data/club-events]] | okur (paylaşılan `eventFeedProvider` üzerinden; takip edilen topluluklara göre öneri, `recommendedHomeEventsProvider`) |
| SharedPreferences `home_quick_actions` | okur/yazar, cihaz yerel (hızlı erişim seçimi) |

Firebase'e yazma yok. Tek yazma, cihaz yerelindeki hızlı erişim seçimi.

## Komşu feature'lar

Kabuk olduğu için **hepsiyle** komşu. `/home` altında üç alt rota barındırıyor: `community`, `board`, `profile` — bunlar sekme değil.

Veri düzeyinde: [[wiki/features/events]] ile aynı etkinlik akışını (`eventFeedProvider`, `FeedEvent`) kullanıyor; kendi etkinlik modeli yok.

## Kararlar

- **Kabuk ile içeriğin ayrılması.** `HomePage` navigasyon iskeletini, `HomeContentPage` ilk sekmenin içeriğini taşıyor. Böylece "ana sayfa" hem kap hem sayfa olabiliyor. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].
- **Ana sayfada kulüp etkinliği yok.** Yalnızca öğrenci etkinlikleri gösteriliyor. Muhtemel sebep: `club-events` alt koleksiyonda ve tümünü çekmek collection-group indeksi ister. Bkz. [[wiki/data/club-events]].

  > **Güncelleme (2026-10-03):** Bu madde artık geçerli değil. Öğrenci etkinlikleri kaldırıldı ([[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]]); ana sayfa yalnızca topluluk etkinliklerini gösteriyor (`recommendedHomeEventsProvider`, `lib/features/home/providers/home_provider.dart`). Bu bölümdeki `limit(10)` maddesi de eski sorguya aitti: `HomeService` artık yalnızca `announcements` okuyor. Madde kullanıcı onayıyla silinebilir.
- **`limit(10)`.** Ana sayfadaki tek limitli sorgu bu — [[wiki/data/announcements]] limitsiz.

## Hızlı erişim kartları çalışmıyor

> **Çelişki (2026-07-28):** `DEVELOPMENT.md` ve `CLAUDE.md` "OBS sayfası `WebView` ile açılır — native entegrasyon yoktur" diyor. Kodda WebView **yok**: `pubspec.yaml` içinde `webview_flutter` veya `url_launcher` bağımlılığı bulunmuyor, ve ana sayfadaki OBS kartının `onTap` gövdesi boş (`home_page.dart:424`).
>
> Aynı durum diğer üç hızlı erişim kartında da geçerli: **TL Yükleme**, **Akademik Takvim**, **Acil Durum** — dördü de `onTap: () {}`. Yani ana sayfadaki hızlı erişim ızgarası bütünüyle görsel bir yer tutucu.
>
> Döküman planlanan davranışı yazmış, kod henüz oraya gelmemiş. Bu bir hata değil eksik iş — ama dökümanı okuyan biri OBS'nin çalıştığını sanır.

> **Güncelleme (2026-10-03):** Yukarıdaki durum artık kodla örtüşmüyor. Kartlar bağlı (OBS `/obs` WebView rotası, TL Yükleme uygulama içi tarayıcı, Akademik Takvim `/academic-calendar`, Acil Güvenlik telefon araması) ve `pubspec.yaml` `webview_flutter` ile `url_launcher` içeriyor. Izgara ayrıca kullanıcı tarafından özelleştirilebilir hale geldi, bkz. aşağıdaki bölüm. Çelişki bloğunu kendiliğimden silmiyorum; kapatmak için kullanıcı onayı gerekir.

## Hızlı erişim ızgarası

Ana sayfada 3 sütun x 2 satır, **her zaman tam 6** kısayol. Katalog 10 öğe: eski dört kart (OBS, TL Yükleme, Akademik Takvim, Acil Güvenlik), Chatbot, Mediko ve Kampüs sekmesindeki dört sayfa (harita, kayıp-buluntu, fotoğraflar, numaralar). İlk altısı varsayılan ızgaradır. Başlığın yanındaki "Düzenle" bir alt sayfa açar: seçili olanlar sürüklenerek sıralanır, çıkarılır, kataloktan eklenir; "Kaydet" yalnızca 6 öğe seçiliyken açılır.

- **Veri yolu.** SharedPreferences anahtarı `home_quick_actions`, `QuickAction` enum adlarının listesi. Kullanıcıya değil cihaza bağlı: hesap değişince seçim kalır, telefon değişince varsayılana döner. Kalıp, `ring_favorite_stops` ile aynı ([[wiki/features/ring]] favori duraklar). Kod: `lib/features/home/services/quick_actions_service.dart`.
- **Neden cihaz yerel.** Kullanıcı, hesaba bağlı Firestore seçeneği yerine bunu seçti (2026-10-03). Seçenekler arasında gerekçe olarak sunulan: Firestore şeması ve güvenlik kuralı değişikliği gerekmemesi. Cihazlar arası senkron gerekirse yalnızca bu servis Firestore'a taşınır; arayüz `quickActionsProvider` üzerinden konuştuğu için değişiklik tek noktada kalır.
- **Bozuk ya da eski kayıt.** Okurken normalize edilir: bilinmeyen id atılır, tekrarlar ayıklanır, eksik yerler varsayılan sırayla doldurulur (`normalizeQuickActions`, `lib/features/home/models/quick_action.dart`). Kayıt `enum.name` olduğu için bir kısayolu yeniden adlandırmak o kullanıcının seçimini sessizce düşürür; ızgara yine tam 6 kalır ama seçim değişmiş görünür.
- **Chatbot ve Mediko.** `/chatbot` ve `/mediko` kök navigator rotaları, `WebPortalPage` ile uygulama içi WebView. Adresler `lib/shared/constants/web_portals.dart` içinde. Bu iki portalın uygulama içinde (oturum, çerez, mobil uyum) sorunsuz çalıştığı cihazda doğrulanmadı.
- **Kampüs sayfaları** `go` ile açılır, sekme de Kampüs'e geçer; `campus_page.dart` ile aynı davranış. Kampüs feature'ının wiki sayfası henüz yok: [[wiki/features/campus]].
- **İkonlar** `font_awesome_flutter` paketinden. Paketin 11. sürümünde `FaIconData`, Flutter'ın `IconData`'sını extend etmez; `FaIcon` ile çizilir.

## Karşılama alanı

**Şu an ana sayfada** eski karşılama var: logo ve avatar satırının altında kalın "Merhaba, <ilk isim> 👋" (`headlineSmall`, isim yoksa "Öğrenci", yüklenirken ve hatada yalnızca "Merhaba 👋") ve altında soluk "Kampüste bugün neler var?". `HomeContentPage` içinde, `currentUserProvider` üzerinden.

2026-10-03'te bu alan kısa süre küçük, soluk bir "Merhaba, X" ile, sonra aşağıdaki "deniz ufku" tasarımıyla değiştirildi; kullanıcı eski hale dönmeyi istedi (emoji dahil). Ufuk tasarımı **kodda duruyor ama ana sayfaya bağlı değil**: `HomeGreeting`, `HorizonVignette`, `DayPart`, `skyPositionAt`, `homeClockProvider`, `homeNowProvider`, `termProgressProvider` ve `AcademicCalendarService.termProgress`. Yeniden bağlamak için `home_page.dart` içindeki karşılama bloğunu `HomeGreeting` ile değiştirmek yeterli. Silinecekse testleri (`test/home_greeting_test.dart`, takvimdeki `termProgress` grubu) ve `homeNowProvider` override'ları da birlikte gider.

Bağlanmayan tasarımın özeti: solda iki küçük soluk satır (saate göre selam ve isim, altında "Güz Yarıyılı, 3. hafta"), sağda 104x44 px'lik kodla çizilmiş bir deniz ufku (gündüz güneş, gece hilal ve yıldızlar, saate göre yayın üzerinde yer değiştirir). Kullanıcı bu yönü üç alternatif (sade + emoji, bilgi çipleri, fotoğraflı şerit) arasından seçmişti.

- **Selam dilimleri.** 05-12 Günaydın, 12-18 İyi günler, 18-22 İyi akşamlar, 22-05 İyi geceler (`DayPart`, `lib/features/home/models/day_part.dart`). İsim yoksa yalnızca selam yazılır.
- **Yarıyıl haftası.** Ders evresinde "Güz Yarıyılı, N. hafta"; N, "Derslerin Başlaması" gününden itibaren gün farkının 7'ye bölümü artı 1. Yani hafta pazartesiye değil başlangıç gününe göre döner. Final ve bütünleme sınavlarında hafta yerine "final sınavları" / "bütünleme sınavları" yazar. Dönem arası ve yazda satır hiç görünmez. Hesap `AcademicCalendarService.termProgress`'te.
- **Güneşin yeri.** `skyPositionAt` (`lib/features/home/models/sky_position.dart`). Gün doğumu ve batımı Antalya için (36.9 K, 30.7 D, UTC+3) her ayın 15'inde NOAA güneş denklemleriyle hesaplanıp 12 dakika değeri olarak koda sabitlendi; aradaki günler iki komşu ay arasında doğrusal ara değerlenir. Hata birkaç dakika mertebesinde. Çizim için yeterli, takvim doğruluğu iddia edilmiyor.
- **Saat dilimi.** Tablo UTC+3 yerel saat varsayar ve cihazın yerel saatini okur; kodda saat dilimi dönüşümü yok. Türkiye dışında bir saat diliminde cihaz, güneşi yanlış yerde gösterir.
- **Canlı kalma.** `homeClockProvider` dakikada bir `DateTime.now()` yayar; selam, güneşin yeri ve hafta uygulama açık kalsa da güncellenir. Ring'in saniyelik `tickerProvider`'ının dakikalık eşi, ama ondan import edilmez.
- **Animasyon.** Güneş ya da ay açılışta ufuktan yerine 900 ms'de bir kez yükselir. Sürekli animasyon yok. "Hareketi azalt" açıksa atlanır. Çizim ekran okuyucudan gizli (`ExcludeSemantics`), yalnızca metin okunur.
- **Test kalıbı.** `HomeContentPage` açan testler `homeNowProvider`'ı sabit bir saatle override etmeli; yoksa dakikalık zamanlayıcı "Timer is still pending" hatası verir. Ring testlerindeki `nowProvider` override'ı ile aynı kalıp.

### Akademik takvimin shared'a taşınması

Hafta hesabı Kampüs feature'ının akademik takvim verisine ihtiyaç duyuyor, ama feature'lar arası import yasak (`CLAUDE.md`). Çözüm: `academic_calendar.dart` (model) ve `academic_calendar_service.dart` `lib/features/campus/` altından `lib/shared/models/` ve `lib/shared/services/` altına taşındı, `academicCalendarServiceProvider` `lib/shared/providers/academic_calendar_provider.dart` içine alındı. Kampüs'e özgü provider'lar (`academicMilestonesProvider`, `publicHolidaysProvider`, `selectedAcademicTermProvider`, `nextAcademicEventProvider`) Kampüs'te kaldı ve paylaşılan servis provider'ını kullanıyor. Veri hâlâ elle derleniyor ve yılda bir güncellenmesi gerekiyor; yeni takvim girilmezse yıl dönümünden sonra karşılama alanının ikinci satırı sessizce kaybolur.

> **Not:** Taşınan ve yeni eklenen dosyalar henüz commit'lenmediği için bu bölüm `code_refs`'e sha ile bağlanmadı; commit'ten sonra eklenmeli.

## Açık sorular

- Bağlanmayan deniz ufku bileşenleri silinecek mi, yoksa başka bir yerde (ör. profil ya da Kampüs sayfası) kullanılmak üzere mi kalacak? Karar bekliyor.
- Chatbot ve Mediko'nun vurgu rengi temada tanımlı olmayan `colorScheme.tertiary` (tohum renkten üretilen). Marka paletiyle (mavi, turuncu, kırmızı) uyumu görsel olarak doğrulanmadı; tek yerde değiştirilir: `lib/features/home/pages/components/quick_action_style.dart`.

- Kulüp etkinliklerinin ana sayfada olmaması bilinçli bir ürün kararı mı, teknik kaçınma mı? Kaynak yok.
- Hızlı erişim kartları hangi sırayla bağlanacak? OBS için WebView mi, tarayıcıya yönlendirme mi?
- Duyuru sorgusunda limit olmaması gözden kaçmış olabilir; duyuru sayısı arttıkça ana sayfa açılışı yavaşlar.
- `board` ve `profile` sekme yerine `/home` altında olması gezinmede keşfedilebilirliği düşürüyor olabilir — kullanıcı verisi yok.
