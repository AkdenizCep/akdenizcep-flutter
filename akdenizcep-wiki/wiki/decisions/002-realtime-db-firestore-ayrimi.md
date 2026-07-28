---
title: 002 — Realtime DB / Firestore ayrımı
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/kod-tabani]]"
---

# 002 — Realtime DB / Firestore ayrımı

## Bağlam

Proje iki Firebase veritabanını birden kullanıyor. Bu alışılmadık bir tercih ve hangi verinin nereye gideceğinin net bir kuralı olması gerekiyor.

## Karar

| Veritabanı | Ne tutar |
| --- | --- |
| **Realtime Database** | Üniversitenin elle girdiği, sık okunan, seyrek değişen veri: [[wiki/data/cafeteria-menu]], [[wiki/data/ring-schedule]], [[wiki/data/ring-stops]] |
| **Firestore** | Kullanıcı verisi ve uygulama içinde üretilen her şey: [[wiki/data/users]], [[wiki/data/clubs]], [[wiki/data/student-events]], [[wiki/data/cafeteria-ratings]], [[wiki/data/board]], [[wiki/data/announcements]], [[wiki/data/feedback]] |

`DEVELOPMENT.md` bunu iki yasak olarak da yazmış: "Realtime DB yerine Firestore'u sık güncellenen veriler (ring, menü) için kullanma — maliyet artar" ve "Yorum veya etkinlik verisi için Realtime DB kullanma — bunlar Firestore'a aittir."

## Gerekçe

**Maliyet.** Firestore doküman okuması başına ücretlendirir. Ring saatleri her açılışta okunuyor ve hiç değişmiyor — Firestore'da bu her kullanıcı için tekrarlanan bir okuma maliyeti. RTDB bant genişliği üzerinden ücretlendirir ve küçük JSON ağaçları ucuzdur.

**Şekil uyumu.** Ring saatleri ve menü doğal olarak ağaç: `tarih → öğün → yemekler`, `hat → gün tipi → saatler`. Doküman koleksiyonuna zorlanmaları yapay olurdu.

**Sorgu ihtiyacı.** Firestore'daki veriler sorgulanıyor (`where('date', ...)`, `orderBy('createdAt')`, `authorUid` filtresi). RTDB'dekiler bütün olarak okunuyor. Bu, ayrımın en net teknik gerekçesi.

## Sonuçları

**Kazanılan:** Maliyet öngörülebilir. Üniversite verisini güncelleyen kişi Console'da basit bir JSON ağacı görüyor, doküman modeliyle uğraşmıyor.

**Ödenen:**

1. **Referans bütünlüğü yok.** [[wiki/data/cafeteria-ratings]] doküman kimliği `{date}_{mealName}` — yani RTDB'deki yemek adının string kopyası. İki veritabanı arasında yabancı anahtar garantisi yok; menüde ad düzeltilirse eski puanlar yetim kalır.
2. **İki güvenlik modeli.** Firestore kuralları repoda (`firestore.rules`), RTDB kuralları hiç yok. Bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].
3. **İki SDK.** [[wiki/features/cafeteria]] her iki veritabanına birden bağlanıyor; servis hem `FirebaseFirestore.instance` hem `FirebaseDatabase.instanceFor(...)` tutuyor.
4. **Şema doğrulaması yok.** RTDB tarafında hata yapılması kolay ve bugün üretimde iki hata var. Bkz. [[wiki/concepts/elle-girilen-veri]].

## Kaynak

`DEVELOPMENT.md` → "Firebase Veri Modeli" ve "Kaçınılması Gerekenler" bölümleri.
