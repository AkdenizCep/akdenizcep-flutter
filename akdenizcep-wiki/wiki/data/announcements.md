---
title: announcements
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/home/services/home_service.dart
    sha: 44ab794
---

# announcements

## Yol

Firestore · `announcements/{announcementId}`

## Şema

`imageUrl` · `title` · `context` · `createdAt`

`context` alan adı `description` değil — `DEVELOPMENT.md` şemasında böyle geçiyor, muhtemelen "içerik" kelimesinin çevirisi.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/home]] | okur (`createdAt` azalan) | `home_service.dart:11` |

## Kısıtlar

- `read`: her Akdeniz öğrencisi
- `write`: **hiç kimse** — duyurular yalnızca Firebase Console'dan girilir

`clubs` ile aynı desen: içerik üniversite/ekip tarafından yönetilir, uygulama salt okur. Bkz. [[wiki/concepts/elle-girilen-veri]].

## Notlar

Sorguda `limit` yok — koleksiyon büyüdükçe ana sayfa tüm duyuruları çeker. Slider bileşeni (`announcement_slider.dart`) hepsini gösteriyor.

> **Açık soru:** Duyuruların bir geçerlilik tarihi yok. Eski duyurular elle silinmezse slider'da kalmaya devam eder.
