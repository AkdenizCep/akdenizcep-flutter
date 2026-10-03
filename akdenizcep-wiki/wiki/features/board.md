---
title: board
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/board/services/board_service.dart
    sha: ae378bb
  - path: lib/app/router.dart
    sha: 089b8e8
---

# board

## Sorumluluk

İlan panosu — öğrencilerin başlık, içerik ve kategoriyle ilan bırakması, listelemesi, kendi ilanını silmesi.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/board]] | okur (liste), yazar (oluştur, sil) |

## Komşu feature'lar

Yok. Kendi koleksiyonunu tek başına kullanan tek feature.

Rotası `/home/board` — sekme değil, ana sayfa altında alt rota. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].

## Kararlar

- **Sadece oluştur/listele/sil.** Düzenleme yok; `update` akışı hiç yazılmamış.
- **`createdAt` azalan sıralama.** En yeni ilan üstte, sayfalama yok.

## En büyük sorun: sunucu tarafı yok

> **Çelişki (2026-07-28):** `firestore.rules` içinde `board` için hiçbir `match` bloğu yok. Firestore eşleşmeyen yolu varsayılan olarak reddettiği için, bu kurallar deploy edildiğinde feature tamamen çalışmaz. Silme yetkisi de yalnızca client'ta kontrol ediliyor (`board_service.dart:45`) — kural eklendiğinde bu koruma sunucuya taşınmalı.
>
> Ayrıntı ve olasılık analizi: [[wiki/data/board]].

Uygulanacak kural yazarlığa bağlı yetki desenidir. Bu desen eskiden `student-events` kuralındaydı (kaldırıldı, bkz. [[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]]); `lost_found_items` kuralında bugün de var:

```
match /board/{itemId} {
  allow read: if isAkdenizStudent();
  allow create: if isAkdenizStudent() &&
    request.auth.uid == request.resource.data.authorUid;
  allow update, delete: if isAkdenizStudent() &&
    request.auth.uid == resource.data.authorUid;
}
```

## Açık sorular

- `category` alanının izinli değerleri hiçbir yerde tanımlı değil — ne enum, ne kural kısıtı.
- İlanların süresi/arşivi yok.
