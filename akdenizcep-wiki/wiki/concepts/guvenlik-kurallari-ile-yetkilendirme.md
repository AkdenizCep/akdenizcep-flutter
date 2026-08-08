---
title: Güvenlik kurallarıyla yetkilendirme
type: concept
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: firestore.rules
    sha: 0c42d94
  - path: lib/features/board/services/board_service.dart
    sha: ae378bb
  - path: lib/features/student_events/services/student_events_service.dart
    sha: 0c42d94
---

# Güvenlik kurallarıyla yetkilendirme

## Tanım

Projede backend yok — Cloud Function, sunucu, API katmanı hiçbiri. Client doğrudan Firestore ve Realtime Database ile konuşuyor. Bu, **tüm yetkilendirmenin güvenlik kurallarında yaşadığı** anlamına gelir. Servis katmanındaki kontroller yalnızca kullanıcı deneyimidir.

Bu bakış, bu projede bir kod incelemesi yaparken sorulacak ilk soruyu belirler: "bu kontrolün sunucu tarafında karşılığı var mı?"

## Projede nasıl uygulanıyor

Üç farklı olgunluk seviyesi var ve ayrımları öğreticidir:

**Doğru desen — [[wiki/data/student-events]].** Yetki hem client'ta (`student_events_service.dart:55,70` dokümanı çekip `authorUid` karşılaştırıyor) hem sunucuda (`resource.data.authorUid == request.auth.uid`) uygulanıyor. Client atlanırsa sunucu tutuyor.

**Yarım desen — [[wiki/data/cafeteria-ratings]].** "Günde bir oy" kuralı yalnızca client'ta (`cafeteria_service.dart:114`). Sunucu `create` iznini `isOwner(uid)` ile veriyor; aynı uid ile ikinci yazma mevcut dokümanın üzerine geçer, engellenmez. Benzer şekilde `avgRating` alanı kural düzeyinde korunmuyor.

**Eksik desen — [[wiki/data/board]].** Kuralda hiçbir `match` bloğu yok. Silme yetkisi tamamen client'ta (`board_service.dart:45`). Kurallar deploy edilirse feature çalışmaz, edilmezse yetkilendirme hiç yok.

**Bilinçli kapatma — [[wiki/data/feedback]].** Her şey reddedilmiş, yalnızca `create` açık. Kuraldaki yorum satırı bunun tasarım olduğunu söylüyor. Bu ayrım önemli: `board`'un eksikliği ile `feedback`'in kısıtlılığı kuralda benzer görünür, ayırt eden şey yazılı gerekçedir.

## Sürüm kontrolü boşluğu

`firebase.json` içinde `firestore` veya `database` deploy hedefi yok — dosya yalnızca FlutterFire yapılandırması taşıyor. Sonuçları:

- `firestore.rules` `firebase deploy` ile yayına alınamaz; Console'a elle yapıştırılmış olmalı
- Repodaki kural dosyası **niyeti** gösterir, üretimdeki durumu değil; ikisi sessizce ayrışabilir
- Realtime Database kuralları repoda hiç yok — `ring_schedule` ve `cafeteria_menu` düğümlerinin erişim durumu koddan bilinemez

> **Açık soru (2026-07-28):** `firebase.json`'a `firestore` ve `database` hedefleri eklenip kurallar deploy hattına alınmalı mı? Bu, [[wiki/data/board]] sorununu görünür kılar (deploy denemesi kuralsız koleksiyonu ortaya çıkarır) ve RTDB kurallarını sürüm kontrolüne sokar.

## İlgili sayfalar

[[wiki/concepts/ogrenci-dogrulama]] · [[wiki/data/board]] · [[wiki/data/feedback]] · [[wiki/data/cafeteria-ratings]] · [[wiki/decisions/007-kulup-etkinligi-adminuid]]
