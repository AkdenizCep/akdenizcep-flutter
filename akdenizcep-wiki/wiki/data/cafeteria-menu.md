---
title: cafeteria_menu
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
---

# cafeteria_menu

## Yol

Realtime Database · `cafeteria_menu/{YYYY-MM-DD}/{mealType}`

## Şema

```json
"cafeteria_menu": {
  "2024-01-15": {
    "lunch": ["Mercimek çorbası", "Tavuk şiş", "Pilav"]
  }
}
```

Tarih → öğün türü → yemek adları dizisi. `mealType` anahtarları veriden gelir (`lunch` görülüyor); kodda sabit liste yok, `MenuItem.mealType` doğrudan anahtarı taşıyor (`cafeteria_service.dart:22-28`).

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/cafeteria]] | okur (tarihe göre `onValue` stream) | `cafeteria_service.dart:18` |

**Yazan yok** — menüyü üniversite Console'dan giriyor. Bkz. [[wiki/concepts/elle-girilen-veri]].

## Durum: üretimde yok

> **Çelişki (2026-07-28):** `realtime_db.json` dökümünde `cafeteria_menu` düğümü hiç yok. Kod bu düğümü okuyor. Yani ya döküm alındığında menü henüz girilmemişti, ya da döküm kısmi. Çözülmedi.

## [[wiki/data/cafeteria-ratings]] ile bağı

Rating dokümanının kimliği `{date}_{mealName}` — yani buradaki yemek adının **birebir kopyası**. Bu iki veritabanı arasındaki tek bağ ve referans bütünlüğü garantisi yok:

- Menüdeki bir yemek adı düzeltilirse (yazım hatası, büyük/küçük harf) eski rating'ler yeni adla eşleşmez
- `mealName` içinde `/` geçerse Firestore doküman kimliği bozulur

Bu, iki ayrı veritabanı kullanmanın maliyeti. Bkz. [[wiki/decisions/002-realtime-db-firestore-ayrimi]].

## Notlar

Tarih anahtarı `YYYY-MM-DD` — Türkçe locale ile biçimlenen arayüz tarihinden ayrı tutulmalı. Uygulama `intl` ile Türkçe gösterir, sorgu bu ISO biçimini kullanır.
