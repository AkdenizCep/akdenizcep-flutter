---
title: firestore.rules
type: source
updated: 2026-07-28
status: current
sources: []
code_refs:
  - path: firestore.rules
    sha: 0c42d94
---

# Kaynak — firestore.rules

## Künye

- **Yol:** `firestore.rules` (repo kökü)
- **Tür:** Firebase Security Rules, `rules_version = '2'`
- **Önemi:** Yetkilendirmenin **sunucu tarafı** gerçeği. Client kodundaki kontroller yalnızca arayüz kolaylığıdır; asıl sınır burada.

## Özet

Dört yardımcı fonksiyon tanımlı:

| Fonksiyon | Ne yapar |
| --- | --- |
| `isSignedIn()` | `request.auth != null` |
| `isAkdenizStudent()` | Giriş yapmış **ve** e-posta `@ogr.akdeniz.edu.tr` ile bitiyor |
| `isOwner(uid)` | `request.auth.uid == uid` |
| `isValidVoteChange(uid)` | `votes` haritasında yalnızca çağıranın kendi anahtarı değişmiş ve değeri `1` veya `-1` |

Neredeyse tüm okuma izinleri `isAkdenizStudent()`'a bağlı — yani wiki'deki "her şey öğrenciye açık" varsayımı doğru. Bkz. [[wiki/concepts/ogrenci-dogrulama]].

Kural verilen yollar: `users`, `clubs`, `clubs/{id}/club-events`, `announcements`, `student-events`, `feedback`, `cafeteria_ratings`, `cafeteria_ratings/{id}/ratings`.

## Kritik bulgu: kuralsız koleksiyon

`board` koleksiyonu için **hiçbir `match` bloğu yok**. Firestore'da eşleşmeyen yol varsayılan olarak reddedilir, yani bu kurallar deploy edildiğinde board feature'ı tamamen çalışmaz hale gelir. Ayrıntı: [[wiki/data/board]].

## Kritik bulgu: avgRating client'a açık

`cafeteria_ratings/{ratingId}` için `allow write: if isAkdenizStudent()` — yani herhangi bir öğrenci `avgRating` ve `ratingCount` alanlarını doğrudan yazabilir. `DEVELOPMENT.md` "bu alanları client'tan direkt yazma" diyor ama kural bunu engellemiyor. Ayrıntı: [[wiki/data/cafeteria-ratings]].

## Deploy edilip edilmediği belirsiz

`firebase.json` yalnızca FlutterFire yapılandırması içeriyor — `firestore` veya `database` deploy hedefi tanımlı değil. Yani bu dosya `firebase deploy --only firestore:rules` ile yayına alınamaz; kurallar Console'a elle yapıştırılmış olmalı.

Bu, Console'daki gerçek kurallarla bu dosyanın ayrışabileceği anlamına gelir. Repodaki `firestore.rules` **niyeti** gösterir, üretimdeki durumu değil. Bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].

## Bu kaynaktan türeyen sayfalar

[[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]] · [[wiki/concepts/ogrenci-dogrulama]] · [[wiki/data/users]] · [[wiki/data/clubs]] · [[wiki/data/club-events]] · [[wiki/data/announcements]] · [[wiki/data/student-events]] · [[wiki/data/feedback]] · [[wiki/data/cafeteria-ratings]] · [[wiki/data/board]] · [[wiki/decisions/003-eposta-domain-kisiti]] · [[wiki/decisions/007-kulup-etkinligi-adminuid]]
