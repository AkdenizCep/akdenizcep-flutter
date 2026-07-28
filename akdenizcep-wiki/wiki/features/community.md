---
title: community
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
---

# community

## Sorumluluk

Kulüpleri listelemek, kulüp detayını ve etkinliklerini göstermek, takip et/bırak akışını yönetmek.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/clubs]] | okur (liste + detay), yazar (`followerCount`) |
| [[wiki/data/club-events]] | okur |
| [[wiki/data/users]] | yazar (`followedClubs`) |

## Komşu feature'lar

- [[wiki/features/profile]] — takip edilen kulüpleri gösteriyor, `clubs` koleksiyonunu bağımsız okuyor
- [[wiki/features/home]] — community sayfasına giriş `/home/community` altından

## Kararlar

- **Kulüp oluşturma uygulamada yok.** `firestore.rules` `create` ve `delete` izinlerini herkese kapatmış; kulüpler Console'dan açılıyor. Bkz. [[wiki/concepts/elle-girilen-veri]].
- **Etkinlik oluşturma da uygulamada yok.** Kural `adminUid` eşleşen kullanıcıya yazma izni veriyor ama karşılık gelen arayüz yazılmamış. Bkz. [[wiki/decisions/007-kulup-etkinligi-adminuid]].
- **Takip iki dokümana batch yazıyor.** Sayaç `FieldValue.increment`, liste `arrayUnion` — ikisi de sunucu operatörü, yarış koşuluna dayanıklı. Ayrıntı: [[wiki/data/clubs]].
- **Etkinlikler kulübün alt koleksiyonunda.** Bu seçim "bu kulübün etkinlikleri"ni ucuzlatıyor, "tüm etkinlikler"i pahalılaştırıyor. Bkz. [[wiki/data/club-events]].

## Açık sorular

- `adminUid` yetkisinin uygulama içinde hiç kullanılmaması, kuralı ölü kod hâline getiriyor. Kulüp yöneticisi arayüzü planlanıyor mu?
- Kulüp listesi limitsiz okunuyor (`community_service.dart:11`) — kulüp sayısı sınırlı olduğu için bugün sorun değil.
- Aynı kullanıcı arayüz atlanarak iki kez takip ederse `followerCount` şişebilir; `arrayUnion` listeyi korur ama sayaç korunmaz.
