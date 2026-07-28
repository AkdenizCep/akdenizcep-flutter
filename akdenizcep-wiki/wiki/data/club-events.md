---
title: club-events
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
---

# club-events

## Yol

Firestore · `clubs/{clubId}/club-events/{ceventId}` — [[wiki/data/clubs]] altında alt koleksiyon.

## Şema

`title` · `date` (timestamp) · `imageUrl` · `location` · `description` · `createdAt`

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/community]] | okur | `community_service.dart:30-32` |

Uygulama içinde **yazan yok**. Kural yazmaya izin veriyor ama client'ta karşılık gelen bir akış yok — kulüp etkinlikleri bugün Console'dan giriliyor.

## Kısıtlar

- `read`: her Akdeniz öğrencisi
- `write`: yalnızca `clubs/{clubId}.adminUid == request.auth.uid`. Kural bunu `get()` çağrısıyla üst dokümandan okuyarak doğruluyor — bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## Notlar

Etkinliğin kulübün **altında** durması, "bu kulübün etkinlikleri" sorgusunu tek bir alt koleksiyon okumasına indiriyor. Karşılığında "tüm kulüplerin yaklaşan etkinlikleri" sorgusu collection-group indeksi gerektirir. [[wiki/features/home]] ana sayfada yaklaşan etkinlikleri gösterirken bu yüzden `club-events`'i değil [[wiki/data/student-events]]'i okuyor.

> **Açık soru:** Ana sayfada kulüp etkinlikleri neden gösterilmiyor — bilinçli bir karar mı, yoksa collection-group sorgusundan kaçınmanın yan etkisi mi? Kaynak yok.
