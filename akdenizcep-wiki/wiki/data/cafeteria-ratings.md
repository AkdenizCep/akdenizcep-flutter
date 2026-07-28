---
title: cafeteria_ratings
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
---

# cafeteria_ratings

## Yol

Firestore · `cafeteria_ratings/{date}_{mealName}` + alt koleksiyon `ratings/{uid}`

Doküman kimliği **bileşik**: `2024-01-15_tavuk-sis`. Yani rating, RTDB'deki [[wiki/data/cafeteria-menu]] girdisine ada göre bağlı — yabancı anahtar değil, string eşleşmesi. Menüdeki yemek adı düzeltilirse eski rating'ler yetim kalır.

## Şema

**Üst doküman:**

| Alan | Tip | Not |
| --- | --- | --- |
| `mealName` | string | |
| `date` | string | `YYYY-MM-DD` |
| `avgRating` | number | Transaction ile hesaplanır |
| `ratingCount` | number | Transaction ile hesaplanır |

**`ratings/{uid}` alt dokümanı:**

| Alan | Tip | Not |
| --- | --- | --- |
| `uid`, `date`, `mealName` | string | Denormalize |
| `rating` | number | 1–5 |
| `comment` | string | Opsiyonel, boş olabilir |
| `authorName` | string | `users/{uid}.name`'den kopyalanır — bkz. [[wiki/concepts/denormalizasyon]] |
| `votes` | map | `{voterUid: 1 | -1}`. Şemada belgelenmemiş, kural ve kod biliyor. |
| `createdAt` | timestamp | |

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/cafeteria]] | okur (rating listesi, yorumlar), yazar (oy verme, yorum oylama) | `cafeteria_service.dart:34,47,80,108` |
| [[wiki/features/profile]] | okur (kullanıcının verdiği puanlar) | `profile_service.dart:50-53` |

## Kısıtlar

- Üst doküman `read`, `write`: her Akdeniz öğrencisi
- `ratings/{uid}` `create`: yalnızca sahibi · `delete`: hiç kimse
- `ratings/{uid}` `update`: yalnızca **başkası** (`request.auth.uid != uid`), yalnızca `votes` alanı, ve `isValidVoteChange` ile yalnızca kendi oy anahtarı

Bu update kuralı zarif: yorum sahibi kendi puanını sonradan değiştiremez, başkaları da yalnızca kendi oyunu ekleyebilir.

## Kritik: avgRating client'a açık

> **Çelişki (2026-07-28):** `DEVELOPMENT.md` "`avgRating` ve `ratingCount` alanlarını client'tan direkt yazma — bunlar yalnızca Cloud Function veya transaction ile güncellenmeli" diyor. Ama `firestore.rules` üst doküman için `allow write: if isAkdenizStudent()` veriyor — yani herhangi bir öğrenci bu alanları keyfi bir değere yazabilir. Kural, dökümanın koyduğu kısıtı **uygulamıyor**. Kod tarafı doğru davranıyor (transaction kullanıyor), sunucu tarafı korumasız.
>
> Ayrıca `DEVELOPMENT.md`'nin şema bölümü "Cloud Function ile güncellenir" diyor; projede Cloud Function yok, güncelleme client transaction'ıyla yapılıyor. Bkz. [[wiki/decisions/004-rating-transaction]].

## Notlar

Günde bir oy kuralı `ratingDocRef.get()` ile **client'ta** kontrol ediliyor (`cafeteria_service.dart:114`). Sunucu tarafında karşılığı `create` izninin `isOwner(uid)` olması — aynı uid ile ikinci `create` mevcut dokümanın üzerine yazar, yani sunucu tekrarı engellemiyor. Bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].

Kendi yorumuna oy verme yasağı da iki yerde: `cafeteria_service.dart:74` client kontrolü, `firestore.rules` `request.auth.uid != uid` sunucu kontrolü. Bu ikisi tutarlı.
