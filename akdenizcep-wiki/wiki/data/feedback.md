---
title: feedback
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
  - path: firestore.rules
    sha: 0c42d94
---

# feedback

## Yol

Firestore · `feedback/{feedbackId}` — kullanıcı geri bildirimleri.

## Şema

En az `uid` alanı var (kural bunu zorunlu kılıyor). Kalan alanlar `profile_service.dart:73`'teki yazma çağrısından okunmalı.

Hiçbir dökümanda belgelenmemiş — ne `DEVELOPMENT.md`'de ne `CLAUDE.md`'de geçiyor.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/profile]] | yazar | `profile_service.dart:73` |

**Okuyan yok.** Bilinçli.

## Kısıtlar

- `create`: öğrenci, **ve** `request.auth.uid == request.resource.data.uid`
- `read`, `update`, `delete`: **hiç kimse** — yazan dahil

Kuraldaki yorum bunu açıkça anlatıyor: geri bildirimler yalnızca Firebase Console'dan okunur. Bu, wiki'deki en net "yazılı gerekçesi olan" tasarım kararlarından biri — tek yönlü kutu deseni.

## Notlar

Kullanıcı gönderdiği geri bildirimi kendisi bile göremiyor. Bu bir eksiklik değil, gizlilik tercihi: geri bildirimlerin uygulama içinde görünmemesi, başka öğrencilerin şikâyetleri okumasını da imkânsız kılıyor.

Karşılaştırma: [[wiki/data/board]]'da hiç kural yok (kaza), burada kural bilinçli olarak her şeyi kapatıyor (tasarım). İkisini ayırt eden şey kuraldaki yorum satırı.
