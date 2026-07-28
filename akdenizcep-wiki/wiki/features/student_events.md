---
title: student_events
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/student_events/services/student_events_service.dart
    sha: 0c42d94
---

# student_events

## Sorumluluk

Öğrencilerin kendi etkinliklerini oluşturması, listelemesi, düzenlemesi ve silmesi. Kulüp etkinliklerinden farkı: **yetki yazarlığa bağlı**, kulüp yöneticiliğine değil.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/student-events]] | okur (liste + detay), yazar (oluştur, güncelle, sil) |

## Komşu feature'lar

Aynı koleksiyonu üç feature okuyor:

- [[wiki/features/home]] — yaklaşan 10 etkinlik
- [[wiki/features/profile]] — kullanıcının kendi etkinlikleri
- bu feature — tümü

Her biri kendi modelini kullanıyor (`StudentEvent`, `HomeEvent`, `ProfileEventSummary`). Cross-feature import yasağına uygun ama şema değişikliği üç yeri birden etkiler.

## Kararlar

- **Yetki hem client hem sunucuda.** Servis silme/düzenleme öncesi dokümanı çekip `authorUid` karşılaştırıyor (`student_events_service.dart:55,70`); kural aynı kontrolü sunucuda yapıyor. Bu, [[wiki/features/board]]'ın aksine doğru desen — bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].
- **Sahiplik yazma anında sabitleniyor.** Kural `create` sırasında `request.resource.data.authorUid == request.auth.uid` istiyor; başkası adına etkinlik açılamıyor.
- **Kendi sekmesi var.** Shell route'un 4. dalı `/student-events`. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].

## Açık sorular

- Liste limitsiz ve sayfalamasız okunuyor. Geçmiş etkinlikler hiç temizlenmiyor — koleksiyon süresiz büyür.
- Etkinlik görseli yok; `club-events`'te `imageUrl` var, burada yok. Bilinçli sadelik mi, eksik mi?
- Silinen etkinliğin [[wiki/features/home]] akışından ne kadar çabuk düştüğü stream'e bağlı; ayrıca doğrulanmadı.
