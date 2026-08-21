---
title: clubs
type: data
updated: 2026-08-21
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/community/services/community_service.dart
    sha: 5a84d8d
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
  - path: firestore.rules
    sha: 5a84d8d
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
| `adminUid` | string | Başkan — kulüp etkinliği yazma yetkisinin ve topluluk ayarları düzenlemenin dayanağı, bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]] |
| `adminUids` | string[] | Başkanın öğrenci numarasıyla eklediği **yönetici üyeler** (2026-08-21). Başkanla aynı yetkiye sahip, `adminUid` bu dizide DEĞİL. Alan yoksa kod boş dizi varsayar — eski dokümanlar migration gerektirmez. |
| `description` | string | |
| `category` | string (Türkçe etiket, örn. `Teknoloji`) | Ayarlar sayfasındaki dropdown'ın seçtiği değer, bkz. [[wiki/features/community]] |
| `logoUrl`, `coverUrl` | string | Cloudinary URL'i (`club-logos/{clubId}`, `club-covers/{clubId}`) |
| `createdAt` | timestamp | |

Alt koleksiyon: **`clubs/{clubId}/members/{uid}`** — `uid`, `name`, `studentId`, `addedAt` (serverTimestamp). Yönetici üyelerin isim/numara görüntüsü için; yetki kontrolü `adminUids`'e dayanır, bu koleksiyona değil.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/community]] | okur (liste + detay + üyeler), yazar (`followerCount`, profil alanları, `adminUids`, `members/*`) | `community_service.dart` |
| [[wiki/features/profile]] | okur (takip edilen kulüpler) | `profile_service.dart:14` |
| [[wiki/features/student_events]] | okur (`adminUid`/`adminUids` — "kimin adına" seçimi) | `event_feed_service.dart:getAdminClubs` |

## Kısıtlar

- `read`: her Akdeniz öğrencisi
- `create`, `delete`: **hiç kimse** — kulüpler yalnızca Firebase Console'dan açılır
- `update`: üç ayrı dal —
  - herkes: yalnızca `followerCount` (takip akışı)
  - başkan **ya da** yönetici üye: yalnızca `name, description, category, logoUrl, coverUrl, foundedYear`
  - **yalnızca başkan**: yalnızca `adminUids` (üye ekleme/çıkarma)
  Her dal `affectedKeys().hasOnly([...])` ile alan bazında izole edilir.
- `members/{uid}` alt koleksiyonu: okuma her öğrenciye açık, `create`/`delete` yalnızca başkana (`isClubPresident`), `update` her zaman kapalı — üye kaydı değil, yalnızca eklenip çıkarılır.

## Notlar

Takip et/bırak işlemi `users/{uid}.followedClubs` ile `clubs/{id}.followerCount` alanlarını tek bir **`WriteBatch`** içinde günceller (`community_service.dart:42-74`). İki koruma birlikte çalışıyor:

- Batch atomiktir — sayaç ile takip listesinin ayrışması engellenmiş
- Sayaç `FieldValue.increment(±1)` ile, liste `arrayUnion`/`arrayRemove` ile güncelleniyor. İkisi de sunucu tarafı operatör olduğu için eşzamanlı iki takip birbirini ezmiyor.

Bu, `firestore.rules`'un `affectedKeys().hasOnly(['followerCount'])` kısıtıyla da uyumlu: batch yalnızca o alana dokunuyor.

> **Açık soru:** Aynı kullanıcının iki kez takip etmesi `arrayUnion` sayesinde listeyi bozmuyor ama `increment(1)` yine de çalışır — sayaç şişebilir. Client bunu buton durumuyla engelliyor; sunucu tarafında karşılığı yok.

Alt koleksiyon: [[wiki/data/club-events]].
