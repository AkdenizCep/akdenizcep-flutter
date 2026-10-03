---
title: Günlük
type: log
updated: 2026-10-03
status: current
---

# Günlük

Kronolojik, append-only. En yeni üstte. Girdi biçimi sabittir:
`grep '^## \[' log.md | head -5` son beş girdiyi verir.

## [2026-10-03] ingest | Öğrenci etkinlikleri kaldırıldı

Kullanıcı öğrencilerin etkinlik oluşturmasını kaldırdı; yalnızca topluluk etkinlikleri kalıyor.
`lib/features/student_events/` `events` olarak yeniden adlandırıldı (sekmeyi ve kulüp etkinliği
oluşturma/düzenleme formunu barındırdığı için silinmedi), `student-events` kuralı ve iki indeksi
silindi, admin panelinden dinleyici ve moderasyon sekmesi çıkarıldı. Mevcut veri yedeksiz silinecek;
silme ve deploy bu girdi yazılırken yapılmamıştı. Yeni: [[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]],
[[wiki/features/events]]. `student_events` ve `student-events` sayfaları linkler kırılmasın diye
"kaldırıldı" notlu yönlendirmeye çevrildi. Değişiklik commit'li olmadığından yeni sayfalar `code_refs`'e
sha'sız. Çözülmeyen: [[wiki/features/home]] ve [[wiki/data/club-events]] içindeki eski çelişki
blokları güncelleme notuyla işaretlendi, silinmedi. Dokunulan sayfalar: [[wiki/index]],
[[wiki/overview]], [[wiki/features/home]], [[wiki/features/profile]], [[wiki/features/board]],
[[wiki/data/clubs]], [[wiki/data/club-events]], [[wiki/concepts/katman-disiplini]],
[[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]], [[wiki/concepts/elle-girilen-veri]],
[[wiki/decisions/002-realtime-db-firestore-ayrimi]], [[wiki/decisions/005-shell-route-navigasyon]],
[[wiki/decisions/007-kulup-etkinligi-adminuid]], [[wiki/sources/kod-tabani]],
[[wiki/sources/firestore-rules]], [[wiki/sources/agent-dokumanlari]].

## [2026-10-03] ingest | Karşılama eski hale döndürüldü

Kullanıcı deniz ufku karşılamasından vazgeçip eski "Merhaba, <isim> 👋" + "Kampüste bugün neler var?"
bloğunu istedi; `home_page.dart` eski bloğa döndü. Ufuk bileşenleri, akademik takvimin `lib/shared/`
altına taşınması ve `termProgress` kodda kaldı ama ana sayfaya bağlı değil; silinip silinmeyeceği açık
soru. Dokunulan sayfalar: [[wiki/features/home]].

## [2026-10-03] ingest | Ana sayfa karşılama alanı (deniz ufku)

Ana sayfaya, logo ve avatarın altına küçük bir karşılama alanı eklendi: saate göre selam, yarıyıl
haftası ve sağda güneşin/ayın saate göre yer değiştirdiği kodla çizilmiş bir ufuk. Hafta hesabı için
akademik takvimin modeli ve servisi `lib/features/campus/` altından `lib/shared/` altına taşındı
(Home, Kampüs'ü import edemez). Gün doğumu/batımı Antalya için ayın 15'lerinde hesaplanmış, aradaki
günler ara değerlenen bir tablo. Görsel hâl cihazda doğrulanmadı. Yeni ve taşınan dosyalar commit'li
olmadığından `code_refs`'e sha'sız. Dokunulan sayfalar: [[wiki/features/home]].

## [2026-10-03] ingest | Özelleştirilebilir hızlı erişim ızgarası

Ana sayfadaki sabit 4 kartlık hızlı erişim, kullanıcının düzenleyebildiği 3x2 ızgaraya dönüştü
(10 öğelik katalog, varsayılan 6: eski dört kart + Chatbot + Mediko). Seçim cihaz yerelinde
(SharedPreferences `home_quick_actions`) tutuluyor; Firebase şeması değişmedi. Chatbot ve Mediko
iki yeni `WebPortalPage` rotası. `home.md` işaretlendi `stale`: sayfadaki "kartlar çalışmıyor"
çelişki bloğu kodla artık örtüşmüyor, silinmedi, kullanıcı onayı bekliyor. Yeni dosyalar henüz
commit'lenmediği için `code_refs`'e sha ile eklenmedi. Dokunulan sayfalar: [[wiki/features/home]].

## [2026-08-24] ingest | au_duraklar.json + au_hatlar.json (ANTOBÜS GTFS)

Ring durak verisi Realtime Database'den asset'e taşındı. `ring_stops` düğümü uzun
süredir yer tutucu adlarla boş duruyordu ve hiçbir hattın `stops` dizisi
girilmemişti; bu yüzden harita, en yakın durak, favoriler ve durak detayı
bütünüyle çalışmıyordu. GTFS türevi 33 durak (`servedBy` + `stopSequence` ile)
ve 4 güzergâh çizgisi uygulamayla birlikte geliyor; RTDB'nin ring sorumluluğu
yalnızca kalkış saatleri kaldı. `RingService.getStops()` ve
`firebase/ring_stops.seed.json` silindi. Dokunulan sayfalar:
[[wiki/data/ring-stops]], [[wiki/data/ring-schedule]], [[wiki/features/ring]],
[[wiki/concepts/elle-girilen-veri]], [[wiki/decisions/008-durak-topolojisi-asset]].

## [2026-08-21] ingest | Kulüp yönetici üyeleri (adminUids + members)

Topluluk ayarları sayfasına (`club_settings_page.dart`) başkanın öğrenci
numarasıyla yönetici üye eklediği bir "Üyeler" bölümü eklendi. Veri modeli:
`clubs/{id}.adminUids` (dizi) + `clubs/{id}/members/{uid}` alt koleksiyonu.
Yönetici üyeler başkanla aynı yetkiye sahip (etkinlik + profil düzenleme),
üye ekleme/çıkarma yalnızca başkanda. `firestore.rules` içindeki
`isClubAdmin` genişletildi, `event_feed_service.dart:getAdminClubs`
`Filter.or` ile iki alanı da kontrol ediyor. Dokunulan sayfalar:
[[wiki/data/clubs]], [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## [2026-07-28] setup | Wiki kuruldu ve ilk tohumlama yapıldı

`llm-wiki.md` deseni projeye uygulandı. Şema `../CLAUDE.md`'ye yazıldı, üç operasyon `.claude/commands/` altında slash komutu oldu (`/wiki-ingest`, `/wiki-query`, `/wiki-lint`). `karpathywiki` Obsidian eklentisi devre dışı bırakıldı — tek yazar disiplini.

Tohumlama HEAD `e36ca3d` üzerinde yapıldı; çalışma ağacında commit edilmemiş değişiklikler vardı (`ring/` dosyaları, `DEVELOPMENT.md`, `router.dart`), `code_refs` SHA'ları son commit'leri gösteriyor.

Oluşturulan: 5 kaynak, 9 feature, 11 veri yolu, 5 kavram, 7 karar sayfası + [[wiki/overview]], [[wiki/index]].

Beş bulgu çıktı, hepsi birden fazla dosyanın karşılaştırılmasından: [[wiki/data/board]] kuralsız · [[wiki/data/ring-stops]] yanlış düğümde · [[wiki/features/home]] hızlı erişim kartları bağlı değil · [[wiki/data/cafeteria-ratings]] `avgRating` korumasız · kurallar deploy hattında değil ([[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]]).

## [2026-07-28] ingest | Kod tabanı taraması

`lib/features/*/services/`, `lib/shared/`, `lib/app/router.dart` tarandı; her Firebase yolu okuyan/yazan feature'a bağlandı. Sayfa: [[wiki/sources/kod-tabani]]. Dokuz feature bulundu, dökümanlar sekiz sayıyor — [[wiki/features/profile]] belgelenmemiş.

## [2026-07-28] ingest | realtime_db.json

Üretim RTDB dökümü. `DEVELOPMENT.md` ile dört çelişki işaretlendi. Sayfa: [[wiki/sources/realtime-db-json]]. Dokunulan: [[wiki/data/ring-schedule]], [[wiki/data/ring-stops]], [[wiki/data/cafeteria-menu]], [[wiki/concepts/elle-girilen-veri]], [[wiki/decisions/006-durak-bazli-saat-yok]].

## [2026-07-28] ingest | firestore.rules

Yetkilendirmenin sunucu tarafı. İki kritik bulgu: `board` kuralsız, `avgRating` client'a açık. Sayfa: [[wiki/sources/firestore-rules]]. Dokunulan: sekiz [[wiki/index|data]] sayfası, [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]], [[wiki/concepts/ogrenci-dogrulama]], [[wiki/decisions/003-eposta-domain-kisiti]], [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## [2026-07-28] ingest | CLAUDE.md ve AGENTS.md

Agent yönergeleri. Feature listesi ve Cloud Function ifadesi kodla çelişiyor. Sayfa: [[wiki/sources/agent-dokumanlari]].

## [2026-07-28] ingest | DEVELOPMENT.md

Otoriter mimari dökümanı. Wiki'nin temeli; kopyalanmadı, link verildi. Sayfa: [[wiki/sources/development-md]]. Dokunulan: [[wiki/concepts/katman-disiplini]], [[wiki/decisions/001-clean-architecture-reddi]], [[wiki/decisions/002-realtime-db-firestore-ayrimi]].
