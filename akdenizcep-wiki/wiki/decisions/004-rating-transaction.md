---
title: 004 — Rating ortalaması transaction ile
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
---

# 004 — Rating ortalaması transaction ile

## Bağlam

Yemek puanlarının ortalaması (`avgRating`) ve oy sayısı (`ratingCount`) her yeni oyda güncellenmeli. İki eşzamanlı oy birbirini ezerse sayaç bozulur. Klasik çözüm Cloud Function tetikleyicisidir.

## Karar

Cloud Function **kullanılmayacak**. Güncelleme client tarafında bir Firestore transaction'ı içinde yapılacak. Transaction üç yazma içeriyor (`cafeteria_service.dart:119-154`):

1. `cafeteria_ratings/{docId}` → yeni `avgRating`, `ratingCount`
2. `cafeteria_ratings/{docId}/ratings/{uid}` → puan, yorum, `authorName`
3. `users/{uid}` → `ratedMealIds` dizisine `arrayUnion`

Yeni ortalama okunan değerlerden hesaplanıyor: `((currentAvg * currentCount) + rating) / newCount`.

## Gerekçe

Cloud Function, Firebase'in Blaze (kullandıkça öde) planını gerektirir. Öğrenci projesi için ücretsiz Spark planında kalmak muhtemelen belirleyici oldu.

Transaction, Cloud Function'ın sağlayacağı atomikliği client'ta sağlıyor: Firestore transaction'ı okuduğu dokümanlar değişirse otomatik yeniden çalışır, yani eşzamanlı iki oy birbirini ezmez.

> **Varsayım:** Blaze planından kaçınma gerekçesi hiçbir yerde yazılı değil; kod ve proje ölçeğinden çıkarıldı.

## Sonuçları

**Kazanılan:** Backend yok, deploy hattı yok, ek maliyet yok. Atomiklik korunuyor.

**Ödenen:**

- **`avgRating` client'a açık kalıyor.** Cloud Function olsaydı kural bu alanı tamamen kapatabilirdi. Transaction client'ta çalıştığı için kuralın yazma izni vermesi zorunlu — ve `firestore.rules` bunu `allow write: if isAkdenizStudent()` ile en geniş hâlde veriyor. Herhangi bir öğrenci keyfi bir ortalama yazabilir. Ayrıntı: [[wiki/data/cafeteria-ratings]].
- **"Günde bir oy" kuralı transaction dışında.** Kontrol transaction'dan önce ayrı bir `get()` ile yapılıyor (`cafeteria_service.dart:114`), yani teorik olarak yarış koşuluna açık.
- **Ortalama yeniden hesaplanamaz.** Kayıtlı ortalamadan ilerleniyor; bir kez bozulursa alt koleksiyondan yeniden türetecek bir mekanizma yok.

## Belgelenmiş hâliyle çelişki

> **Çelişki (2026-07-28):** `DEVELOPMENT.md`'nin Firestore şema bölümü `avgRating` ve `ratingCount` alanlarının yanına "Cloud Function ile güncellenir" yazmış. Aynı dökümanın "Yapılması Gerekenler" listesi ise transaction diyor. Kodda Cloud Function yok. Şema bölümündeki yorum eski bir plandan kalmış olmalı.

## Kaynak

`cafeteria_service.dart:98-158`; `DEVELOPMENT.md` → "Yapılması Gerekenler" ve "Önemli Notlar".
