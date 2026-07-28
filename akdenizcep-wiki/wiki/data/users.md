---
title: users
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/auth/services/auth_service.dart
    sha: 089b8e8
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
  - path: lib/shared/providers/user_provider.dart
    sha: 089b8e8
---

# users

## Yol

Firestore · `users/{uid}` — doküman kimliği Firebase Auth UID'si.

## Şema

| Alan | Tip | Not |
| --- | --- | --- |
| `name` | string | Kayıtta girilir; yorumlara denormalize edilir — bkz. [[wiki/concepts/denormalizasyon]] |
| `email` | string | `@ogr.akdeniz.edu.tr` |
| `studentId` | string | Öğrenci numarası |
| `followedClubs` | string[] | Kulüp kimlikleri |
| `ratedMealIds` | string[] | `{tarih}_{yemekAdi}` biçiminde; `DEVELOPMENT.md` şemasında **yok**, kod yazıyor |
| `createdAt` | timestamp | Sunucu zamanı |

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/auth]] | yazar (kayıtta doküman oluşturur) | `auth_service.dart:45` |
| [[wiki/features/community]] | yazar (`followedClubs` batch güncellemesi) | `community_service.dart:46,63` |
| [[wiki/features/cafeteria]] | yazar (`ratedMealIds` transaction içinde) | `cafeteria_service.dart:151` |
| [[wiki/features/profile]] | okur (dolaylı, `user_provider` üzerinden) | `profile_page.dart` |
| shared | okur (stream) | `shared/providers/user_provider.dart:24` |

## Kısıtlar

`firestore.rules`:

- `read`: her Akdeniz öğrencisi — yani bir öğrenci diğerinin `email` ve `studentId` alanlarını okuyabilir
- `create`, `update`: yalnızca sahibi (`isOwner(uid)`)
- `delete`: hiç kimse

## Notlar

- Okuma izninin tüm öğrencilere açık olması, yorumlarda yazar adını denormalize etme ihtiyacıyla birlikte düşünülmeli — teknik olarak `users` doğrudan okunabilirken ad yine de kopyalanıyor. Bkz. [[wiki/concepts/denormalizasyon]].
- `ratedMealIds` alanı dökümanda yok ama kodda yazılıyor. Profil sayfasındaki "oy verdiğim yemekler" bölümü buna dayanıyor.

> **Varsayım:** `ratedMealIds`, `cafeteria_ratings/*/ratings` alt koleksiyonunda collection-group sorgusu yapmamak için tutulan bir indeks. Kodda bu gerekçe yazılı değil.
