---
title: 009 — Öğrenci etkinlikleri kaldırıldı
type: decision
updated: 2026-10-03
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
---

# 009 — Öğrenci etkinlikleri kaldırıldı

> **Not:** Değişiklik henüz commit'lenmediği için bu sayfa `code_refs`'e sha ile bağlanmadı; commit'ten sonra eklenmeli.

## Bağlam

Uygulamada iki tür etkinlik vardı: kulüplerin düzenlediği ([[wiki/data/club-events]]) ve herhangi bir öğrencinin kendi adına açtığı (`student-events`). İkisinin yetki modeli farklıydı: bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## Karar

Öğrencilerin etkinlik oluşturması kaldırıldı. Uygulamada yalnızca topluluk etkinlikleri kalır. `student-events` koleksiyonu ve onu okuyan/yazan her şey (uygulama, kurallar, indeksler, admin paneli) çıkarıldı.

Karar kullanıcıdan "artık sadece topluluk etkinlikleri olacak" olarak geldi (2026-10-03). Ürün gerekçesi yazılı olarak verilmedi.

## Gerekçe

Kaynakta kayıtlı bir gerekçe yok. Teknik sonuç olarak yetki modeli tek parçaya iniyor: etkinlik açmak kulüp yöneticisine bağlı, yazarlığa bağlı ikinci bir model kalmadı.

## Sonuçları

**Uygulama (Flutter)**

- `lib/features/student_events/` → `lib/features/events/`. Klasör silinmedi çünkü Etkinlikler sekmesini, kulüp etkinliği oluşturma formunu ve düzenleme sayfasını barındırıyordu. Bkz. [[wiki/features/events]].
- Rota `/student-events` → `/events`. Shell branch indeksi (3) aynı, bkz. [[wiki/decisions/005-shell-route-navigasyon]].
- `EventSource` enum'u ve `EventRef.student` kalktı. `EventRef` artık `{clubId, eventId}`, `FeedEvent.clubId` zorunlu.
- Etkinlik oluşturma yalnızca bir topluluğu yöneten kullanıcıya açık. "Kendi adıma" seçeneği yok; birden fazla topluluk yönetenler seçici görür, tek topluluğu olan görmez.
- Profilde "Oluşturduğum" bölümü ve `/profile/created-events` rotası kalktı. [[wiki/features/profile]] yalnızca katılınan etkinlikleri gösteriyor.
- Etkinlik detayındaki silme düğmesi kalktı: yalnızca öğrenci detay sayfası kullanıyordu. Topluluk etkinliği silme uygulamadan yapılmıyor.

**Firebase**

- `firestore.rules`: `student-events` bloğu (ve `comments` alt koleksiyonu) silindi. Eşleşen kural olmadığı için koleksiyona erişim reddedilir; admin dahil. Test: `functions/test/firestore-content.rules.test.ts`.
- `firestore.indexes.json`: iki `student-events` bileşik indeksi silindi.
- Cloud Functions, RTDB kuralları, Storage ve FCM'de `student-events` ile ilgili bir şey yoktu; dokunulmadı.

**Admin paneli:** `studentEvent` içerik türü, dinleyici ve "Öğrenci etkinlikleri" moderasyon sekmesi kalktı.

**Ödenenler**

- Kulüp yöneticisi olmayan öğrenci hiçbir etkinlik açamaz.
- Eski uygulama sürümleri `student-events` sorgusunda izin hatası alır. Birleşik akış tek stream olduğu için hata sürümde yalnızca öğrenci kısmını değil Etkinlikler sekmesinin tamamını etkiler. Kullanıcı bunu "tek seferde" kaldırma kararıyla kabul etti.
- Mevcut `student-events` dokümanları **yedeksiz silinecek** (kullanıcı kararı), geri alınamaz.

## Durum

Kod ve kural değişiklikleri repoda. Canlıya alma (kural ve indeks deploy'u, veri silme, admin panelinin yayını) bu sayfa yazılırken **yapılmamıştı**; yapılınca bu satır güncellenmeli.

## Kaynak

Kullanıcı talimatı (2026-10-03); `firestore.rules`, `firestore.indexes.json`, `lib/shared/services/event_feed_service.dart`, `lib/shared/models/feed_event.dart`, `lib/features/events/`.
