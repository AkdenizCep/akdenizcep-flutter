---
title: Denormalizasyon
type: concept
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
---

# Denormalizasyon

## Tanım

Firestore'da join yok. Bir ekranda iki koleksiyondan veri gerekiyorsa ya iki okuma yapılır ya da veri kopyalanır. Bu proje üç yerde kopyalamayı seçmiş — her biri farklı bir gerekçeyle ve farklı bir bayatlama riskiyle.

## Projede nasıl uygulanıyor

**1. `authorName` — yorumda yazar adı.**
`cafeteria_ratings/{id}/ratings/{uid}.authorName`, yazma anında `users/{uid}.name`'den kopyalanıyor (`cafeteria_service.dart:146`).

Gerekçe: yorum listesinde N yorum için N kullanıcı dokümanı okumaktan kaçınmak.

Bayatlama: kullanıcı adını değiştirirse eski yorumlarda eski ad kalır. Bugün profil düzenleme akışı var ([[wiki/features/profile]]), yani bu senaryo gerçek.

> **Açık soru:** Ad değişikliğinde eski yorumlar güncellenmeli mi? Firestore'da bu bir toplu yazma işi gerektirir ve client'tan yapılması pahalı. Kabul edilmiş bir bayatlık olabilir — ama hiçbir yerde yazılı değil.

**2. `followerCount` — kulüp takipçi sayacı.**
`clubs/{id}.followerCount`, `users/*.followedClubs` dizilerinin sayımı yerine tutuluyor.

Gerekçe: kulüp listesinde her kulüp için takipçi saymak imkânsız (collection-group + count).

Bayatlama riski düşük: `FieldValue.increment` ve `arrayUnion` aynı batch'te, ikisi de sunucu operatörü. Ayrıntı: [[wiki/data/clubs]].

**3. `ratedMealIds` — kullanıcının puanladığı yemekler.**
`users/{uid}.ratedMealIds` dizisi, rating transaction'ı içinde `arrayUnion` ile büyütülüyor (`cafeteria_service.dart:151`).

Gerekçe: [[wiki/features/profile]]'ın "puanladığım yemekler" bölümü için collection-group sorgusundan kaçınmak.

Bayatlama riski düşük: aynı transaction içinde yazılıyor, yani rating ile indeks birlikte oluşuyor. Ama `ratings/{uid}` silinemediği için (kural `delete: if false`) bu indeks hiç küçülmüyor — tutarlı kalıyor.

Not: `ratedMealIds` alanı `DEVELOPMENT.md` şemasında yok. Bkz. [[wiki/data/users]].

**4. Yarı-denormalizasyon: `ratings/{uid}` içinde `uid`, `date`, `mealName`.**
Bu alanlar doküman kimliğinden ve üst dokümandan zaten çıkarılabilir ama yine de yazılıyor. Muhtemelen sorgulanabilirlik için.

## Değerlendirme

Üç kopyalamanın ikisi transaction/batch ile korunmuş, biri (`authorName`) korunmasız ve kabul edilmiş bir bayatlık. Bu, projenin denormalizasyona bilinçli yaklaştığını gösteriyor — ama `authorName` için yazılı bir karar yok.

## İlgili sayfalar

[[wiki/data/cafeteria-ratings]] · [[wiki/data/clubs]] · [[wiki/data/users]] · [[wiki/decisions/004-rating-transaction]] · [[wiki/concepts/katman-disiplini]]
