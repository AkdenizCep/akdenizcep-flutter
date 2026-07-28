---
title: board
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/board/services/board_service.dart
    sha: ae378bb
  - path: firestore.rules
    sha: 0c42d94
---

# board

## Yol

Firestore · `board/{itemId}` — ilan panosu.

## Şema

| Alan | Tip |
| --- | --- |
| `authorUid` | string |
| `title` | string |
| `content` | string |
| `category` | string |
| `createdAt` | timestamp |

Şema `board_service.dart:27-33`'teki yazma çağrısından çıkarıldı — hiçbir dökümanda belgelenmemiş.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/board]] | okur (liste), yazar (oluştur, sil) | `board_service.dart:10,27,48` |

## Kısıtlar

**Hiçbiri.** `firestore.rules` içinde `board` için `match` bloğu yok.

> **Çelişki (2026-07-28):** Firestore'da eşleşmeyen yol varsayılan olarak **reddedilir**. Bu kurallar deploy edildiğinde `board` koleksiyonuna hiçbir okuma ve yazma geçmez — board feature'ı tamamen çalışmaz hâle gelir. Kodda feature yaşıyor, rotası var (`/home/board`, `router.dart:101-104`), ama sunucu tarafı yok.
>
> İki olasılık: (a) kurallar henüz deploy edilmedi ve veritabanı hâlâ test modunda, (b) board feature kurallar yazıldıktan sonra eklendi ve kural güncellemesi unutuldu. `board_service.dart` son commit'i `ae378bb`, `firestore.rules` son commit'i `0c42d94` — **kurallar board'dan sonra yazılmış**, yani (b) daha az olası; muhtemelen board yazılırken kurala eklenmesi atlandı.

## Notlar

Silme yetkisi yalnızca client'ta: `board_service.dart:45` dokümanı çekip `authorUid` karşılaştırıyor. Sunucu kuralı olmadığı için bu koruma hiç yok sayılabilir — kurallar eklendiğinde `student-events` deseninin (`resource.data.authorUid == request.auth.uid`) aynısı uygulanmalı. Bkz. [[wiki/data/student-events]], [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].

`category` alanının izinli değerleri hiçbir yerde tanımlı değil — ne kodda enum, ne kuralda kısıt.
