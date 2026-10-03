---
title: events
type: feature
updated: 2026-10-03
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/firestore-rules]]"
---

# events

> **Not:** Değişiklik henüz commit'lenmediği için bu sayfa `code_refs`'e sha ile bağlanmadı; commit'ten sonra eklenmeli.

## Sorumluluk

Etkinlikler sekmesi (shell branch 3, `/events`): topluluk etkinliklerinin akışı (kategori ve arama filtresi), etkinlik oluşturma/düzenleme formu ve konum seçici. Eskiden `student_events` adını taşıyordu ve öğrenci etkinliklerini de içeriyordu; bkz. [[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]].

Etkinlik **detayı** bu feature'da değil: [[wiki/features/community]] altındaki `event_detail_page.dart` (`/club/:clubId/event/:eventId`).

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/club-events]] | okur (`collectionGroup`, `moderationStatus == 'visible'`, `date` azalan); yazar (oluştur, güncelle) |
| [[wiki/data/clubs]] | okur (kulüp adı/logosu eşleme; `getAdminClubs` ile kullanıcının yönettiği kulüpler) |

Veri katmanı bu klasörde değil, `lib/shared/` altında: `event_feed_service.dart`, `event_feed_provider.dart`, `feed_event.dart`. Sebep: [[wiki/features/home]] ve [[wiki/features/profile]] aynı akışı okuyor ve feature'lar arası import yasak. Feature klasöründe model, servis ya da provider yok; yalnızca `pages/`.

## Komşu feature'lar

- [[wiki/features/community]] — etkinlik detayı, QR yoklama, düzenleme rotası.
- [[wiki/features/home]] — aynı akıştan takip edilen topluluklara göre öneri üretiyor.
- [[wiki/features/profile]] — "Katıldığım etkinlikler" aynı akıştan türetiliyor.

## Kararlar

- **Oluşturma yetkisi hem arayüzde hem sunucuda.** `adminClubsProvider` boşsa "+" düğmesi çizilmez ve form yerine "Etkinlik oluşturmak için bir topluluğun yöneticisi olmalısın." ekranı gelir. Asıl koruma kuraldaki `isClubAdmin`; bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]].
- **Düzenlemede topluluk değişmez.** Düzenleme modu `adminClubsProvider`'ı hiç okumaz; etkinliğin `clubId`'si sabit kalır.
- **Çok kulüplü yönetici seçici görür.** Tek kulüp yönetiyorsa seçici yok, o kulüp kullanılır. Birden fazlasında ilki varsayılan.
- **Kendi sekmesi var.** Bkz. [[wiki/decisions/005-shell-route-navigasyon]].

## Açık sorular

- Akış `collectionGroup('club-events')`'i limitsiz ve sayfalamasız okuyor, ayrıca her değişiklikte tüm `clubs` koleksiyonunu dinliyor. Geçmiş etkinlikler temizlenmiyor; ölçek sorunu olmadan önce sayfalama ya da arşivleme kararı gerekecek.
- Topluluk etkinliğini uygulamadan silmenin bir yolu yok (silme düğmesi öğrenci etkinlikleriyle birlikte kalktı). Kurala göre kulüp yöneticisi silebilir; arayüzü yazılmadı.
