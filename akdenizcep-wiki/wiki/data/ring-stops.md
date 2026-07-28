---
title: ring_stops
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/ring/services/ring_service.dart
    sha: a32558f
  - path: firebase/ring_stops.seed.json
    sha: e36ca3d
  - path: firebase/README.md
    sha: e36ca3d
---

# ring_stops

## Yol

Realtime Database · `ring_stops/{stopId}`

## Şema

```json
"rektorluk": { "name": "Rektörlük", "lat": 36.8969, "lng": 30.6364 }
```

Ortak bir **durak havuzu**. Hatlar buraya [[wiki/data/ring-schedule]]'ın `stops` dizisiyle sıralı referans verir. Bir durak birden çok hatta geçebilir; "bu duraktan hangi hatlar geçiyor" sorusu bu referanslardan hesaplanır, veride tutulmaz.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/ring]] | okur (`onValue` stream) | `ring_service.dart:27` |

## Durum: bugün boş

> **Çelişki (2026-07-28):** `RingService.getStops()` `ring_stops` düğümünü okuyor, ama `realtime_db.json` dökümünde duraklar **kök düğümde** duruyor (`durak_1`, `durak_2`, `durak_3`) — `ring_stops` altında değil. Yani bugün üretimde durak listesi boş dönüyor.
>
> Zincirleme sonuçlar:
> - Yön seçici gerçek durak adı yerine "Gidiş / Dönüş"e düşüyor
> - "Yakındaki Duraklar" girişi hiç gösterilmiyor
> - `ring_stops_page`, `stops_map`, `nearest_stop_button` bileşenleri boş durumda kalıyor
>
> `DEVELOPMENT.md` bu düşüş davranışını bilinçli bir tasarım olarak anlatıyor: "uydurma durak adı gösterilmez". Yani kod doğru davranıyor, eksik olan veri.

## Bekleyen iş

`firebase/README.md` düzeltmeyi adım adım yazmış:

1. `firebase/ring_stops.seed.json` dosyasındaki üç durağın `name` alanı hâlâ `__DOLDUR__` — gerçek adlar girilmeden yüklenmemeli, çünkü bu adlar doğrudan arayüzde görünür
2. Console → Realtime Database → **`ring_stops` düğümü seçili hâlde** JSON içe aktar. Kök düğümde aktarılırsa `ring_schedule` dahil her şey silinir.
3. Anahtarlar (`durak_1`…) okunabilir slug'lara çevrilmeli (`rektorluk`, `ziraat`)
4. Her hattın `stops` dizisine güzergâh sırasına göre durak anahtarları eklenmeli

Koordinatlar batıdan doğuya `durak_1 → durak_2 → durak_3` sırasında.

## Notlar

Durak adlarının veriden gelmesi — kodda sabit liste olmaması — üniversitenin hat/durak değiştirmesini kod değişikliği olmadan mümkün kılıyor. Bkz. [[wiki/concepts/elle-girilen-veri]].
