---
title: cafeteria
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
---

# cafeteria

## Sorumluluk

Günlük yemekhane menüsünü göstermek, öğrencinin yemeğe puan ve yorum vermesini sağlamak, yorumların faydalı/faydasız oylanmasını yönetmek.

**İki veritabanına birden dokunan tek feature.** Menü RTDB'de, puanlar Firestore'da. Bkz. [[wiki/decisions/002-realtime-db-firestore-ayrimi]].

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/cafeteria-menu]] | okur (RTDB, tarihe göre) |
| [[wiki/data/cafeteria-ratings]] | okur (puanlar + yorumlar), yazar (oy, yorum, yorum oylaması) |
| [[wiki/data/users]] | yazar (`ratedMealIds`, transaction içinde) |

## Komşu feature'lar

- [[wiki/features/profile]] — kullanıcının verdiği puanları `cafeteria_ratings/*/ratings/{uid}` üzerinden okuyor. Yani rating verisi iki feature tarafından paylaşılıyor.
- [[wiki/features/auth]] — `authorName` alanı için kullanıcı adına ihtiyaç var.

## Kararlar

- **Transaction ile atomik ortalama.** `avgRating` ve `ratingCount`, yeni puan ve yorum yazımıyla aynı transaction içinde güncelleniyor. Cloud Function yok. Bkz. [[wiki/decisions/004-rating-transaction]].
- **Günde bir oy.** `ratings/{uid}` dokümanının varlığı kontrol edilerek uygulanıyor (`cafeteria_service.dart:114`). Doküman kimliği tarihi içerdiği için ertesi gün aynı yemeğe yeniden oy verilebilir.
- **Yazar adı denormalize.** `authorName` yazma anında kopyalanıyor — bkz. [[wiki/concepts/denormalizasyon]].
- **Yorum oylaması `votes` haritasıyla.** Ayrı alt koleksiyon yerine tek dokümanda map. Sunucu kuralı `isValidVoteChange` ile yalnızca çağıranın kendi anahtarını değiştirmesine izin veriyor.
- **Yorum sıralaması client'ta.** `orderBy('createdAt')` ile çekilip sonra oy skoruna göre yeniden sıralanıyor (`cafeteria_service.dart:56-60`) — Firestore'da oy skoruna göre sıralama mümkün değil çünkü skor map'ten hesaplanıyor.

## Açık sorular

- Sunucu tarafı `avgRating`'i korumuyor; herhangi bir öğrenci keyfi ortalama yazabilir. Ayrıntı ve çelişki: [[wiki/data/cafeteria-ratings]].
- Günde bir oy kuralı yalnızca client'ta. Sunucu ikinci `create`'i engellemiyor.
- Client tarafı yeniden sıralama, yorum sayısı büyüdüğünde tüm alt koleksiyonu çekmeyi gerektiriyor — sayfalama yok.
- Yemek adı menüde düzeltilirse eski puanlar yetim kalır. Bkz. [[wiki/data/cafeteria-menu]].
