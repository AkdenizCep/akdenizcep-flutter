---
title: 005 — StatefulShellRoute ile sekmeli navigasyon
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/app/router.dart
    sha: 089b8e8
---

# 005 — StatefulShellRoute ile sekmeli navigasyon

## Bağlam

Uygulama sekmeli bir alt navigasyona sahip. Sekmeler arası geçişte her sekmenin kendi gezinme yığını ve kaydırma konumu korunmalı.

## Karar

`go_router`'ın `StatefulShellRoute.indexedStack` yapısı kullanılacak. Beş dal (`router.dart:68-171`):

| # | Yol | Feature |
| --- | --- | --- |
| 0 | `/home` | [[wiki/features/home]] |
| 1 | `/cafeteria` | [[wiki/features/cafeteria]] |
| 2 | `/ring` | [[wiki/features/ring]] |
| 3 | `/student-events` | [[wiki/features/student_events]] |
| 4 | `/map` | [[wiki/features/map]] |

Her dala ayrı `GlobalKey<NavigatorState>` veriliyor — kod içindeki yorum sebebini yazmış: "birden fazla branch aynı yolu paylaşmasın".

Sekme olmayan feature'lar `/home` altında alt rota: `/home/community`, `/home/board`, `/home/profile`.

## Gerekçe

`indexedStack` her dalı bellekte canlı tutar, yani sekme değiştirip dönünce sayfa yeniden kurulmuyor — stream'ler yeniden abone olmuyor, kaydırma konumu korunuyor. Firestore stream'lerine dayanan bir uygulamada bu doğrudan okuma maliyeti demek.

Beş sekme sınırı arayüz kısıtı: alt navigasyonda beşten fazlası sığmıyor. Dokuz feature'ın dördü bu yüzden alt rotaya inmiş.

## Sonuçları

**Kazanılan:** Sekme durumu korunuyor. Derin bağlantılar çalışıyor (`/home/community/:clubId/event/:eventId` dört seviye).

**Ödenen:**

- [[wiki/features/board]] ve [[wiki/features/profile]] ana sayfa altında gizli — keşfedilebilirlikleri düşük
- Tüm dallar bellekte canlı, yani beş sayfanın stream'leri aynı anda açık
- `HomePage` hem kabuk hem içerik taşımak zorunda kaldı; içerik `HomeContentPage`'e ayrıldı

**Kimlik doğrulama yönlendirmesi kabuğun dışında:** `redirect` üç aşamalı — giriş yok, doğrulanmamış, tamam (`router.dart:40-57`). Bkz. [[wiki/features/auth]].

## Açık soru

Sekme dağılımı kullanım verisine dayanmıyor. `board` ve `profile`'ın gizli kalması bilinçli bir öncelik sıralaması mı, yoksa beş sekme sınırının dayattığı bir sonuç mu?

## Kaynak

`lib/app/router.dart`.
