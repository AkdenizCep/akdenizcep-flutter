---
title: student-events
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/student_events/services/student_events_service.dart
    sha: 0c42d94
  - path: lib/features/home/services/home_service.dart
    sha: 44ab794
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
---

# student-events

## Yol

Firestore · `student-events/{seventId}`

## Şema

| Alan | Tip | Not |
| --- | --- | --- |
| `title` | string | |
| `authorUid` | string | Yetkinin dayanağı |
| `date` | timestamp | Etkinlik tarihi |
| `location` | string | |
| `description` | string | |
| `createdAt` | timestamp | |

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/student_events]] | okur (liste + detay), yazar (oluştur, güncelle, sil) | `student_events_service.dart:10,22,36,59,74` |
| [[wiki/features/home]] | okur (yaklaşan 10 etkinlik) | `home_service.dart:24` |
| [[wiki/features/profile]] | okur (`authorUid` = kullanıcı) | `profile_service.dart:26` |

**Üç feature'ın paylaştığı tek koleksiyon** — bu yüzden şema değişikliğinin etki alanı en geniş olan yer burası. Her biri kendi modeliyle okuyor: `StudentEvent`, `HomeEvent`, `ProfileEventSummary`.

## Kısıtlar

- `read`: her Akdeniz öğrencisi
- `create`: öğrenci, **ve** `request.resource.data.authorUid == request.auth.uid` — başkası adına etkinlik açılamaz
- `update`, `delete`: yalnızca `resource.data.authorUid == request.auth.uid`

Kulüp etkinliğinin aksine burada yetki kulüp yöneticiliğine değil, yazarlığa bağlı. Karşılaştırma: [[wiki/data/club-events]], [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## Notlar

`home_service.dart` sorgusu `date >= now` + `orderBy(date)` + `limit(10)`. Bu birleşim Firestore'da **bileşik indeks** gerektirmez (tek alan üzerinde eşitsizlik + sıralama) ama alan adı değişirse üç feature birden kırılır.

> **Açık soru:** Geçmiş etkinlikler hiç temizlenmiyor. Koleksiyon süresiz büyüyor; `student_events_page` tüm koleksiyonu limit'siz okuyor (`student_events_service.dart:10`). Ölçek sorunu olmadan önce sayfalama veya arşivleme kararı gerekecek.
