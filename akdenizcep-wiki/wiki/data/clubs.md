---
title: clubs
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
---

# clubs

## Yol

Firestore · `clubs/{clubId}`

## Şema

| Alan | Tip | Not |
| --- | --- | --- |
| `name` | string | |
| `logoUrl` | string | Firebase Storage |
| `category` | string | |
| `followerCount` | number | Takip akışında güncellenir |
| `adminUid` | string | Kulüp etkinliği yazma yetkisinin dayanağı — bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]] |
| `createdAt` | timestamp | |

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/community]] | okur (liste + detay), yazar (`followerCount`) | `community_service.dart:11,22,49,66` |
| [[wiki/features/profile]] | okur (takip edilen kulüpler) | `profile_service.dart:14` |

## Kısıtlar

- `read`: her Akdeniz öğrencisi
- `create`, `delete`: **hiç kimse** — kulüpler yalnızca Firebase Console'dan açılır
- `update`: yalnızca `followerCount` alanı değişiyorsa. Kural `affectedKeys().hasOnly(['followerCount'])` ile bunu zorluyor.

## Notlar

Takip et/bırak işlemi `users/{uid}.followedClubs` ile `clubs/{id}.followerCount` alanlarını tek bir **`WriteBatch`** içinde günceller (`community_service.dart:42-74`). İki koruma birlikte çalışıyor:

- Batch atomiktir — sayaç ile takip listesinin ayrışması engellenmiş
- Sayaç `FieldValue.increment(±1)` ile, liste `arrayUnion`/`arrayRemove` ile güncelleniyor. İkisi de sunucu tarafı operatör olduğu için eşzamanlı iki takip birbirini ezmiyor.

Bu, `firestore.rules`'un `affectedKeys().hasOnly(['followerCount'])` kısıtıyla da uyumlu: batch yalnızca o alana dokunuyor.

> **Açık soru:** Aynı kullanıcının iki kez takip etmesi `arrayUnion` sayesinde listeyi bozmuyor ama `increment(1)` yine de çalışır — sayaç şişebilir. Client bunu buton durumuyla engelliyor; sunucu tarafında karşılığı yok.

Alt koleksiyon: [[wiki/data/club-events]].
