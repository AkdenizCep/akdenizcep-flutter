---
title: ring_schedule
type: data
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/ring/services/ring_service.dart
    sha: a32558f
  - path: lib/features/ring/models/ring_schedule.dart
    sha: a32558f
---

# ring_schedule

## Yol

Realtime Database · `ring_schedule/{lineId}`

Firestore değil — sık okunan, seyrek değişen ve dokümanı olmayan veri. Bkz. [[wiki/decisions/002-realtime-db-firestore-ayrimi]].

## Şema

```json
"au_103_gidis": {
  "weekday": ["06:31", "06:51", ...],
  "weekend": ["06:31", "06:56", ...],
  "stops": ["durak_1", "durak_2"]
}
```

| Alan | Tip | Not |
| --- | --- | --- |
| `weekday` | string[] | `HH:mm`, **kalkış noktasından** ayrılış saatleri |
| `weekend` | string[] | Aynı |
| `stops` | string[] | **Opsiyonel.** [[wiki/data/ring-stops]] anahtarlarına sıralı referans |

## Hat anahtarı sözleşmesi

`<hatKodu>_<yön>`, yön eki `gidis` veya `donus`. Hat listesi uygulamada sabit tutulmaz, bu anahtarlardan türetilir.

Anahtar iki biçimde giriliyor: `au102_gidis` (dökümanda) ve `au_103_gidis` (üretimde). `RingSchedule.lineCode` ara alt çizgileri temizleyerek ikisini de aynı hatta indiriyor — aksi hâlde `au_102_gidis` hat kodu olarak yalnızca `au` verir ve tüm hatlar tek düğmede toplanırdı. Kodun içindeki yorum bu düzeltmeyi açıkça anlatıyor (`ring_schedule.dart:20-23`).

> **Not:** Bu, wiki'nin en somut örneklerinden biri — üretim verisindeki bir tutarsızlık, kodda savunma mantığı doğurmuş. Veri temizlenirse bu mantık silinebilir hâle gelir.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/ring]] | okur (`onValue` stream) | `ring_service.dart:15` |

**Yazan yok.** Veriyi üniversite Console'dan giriyor. Bkz. [[wiki/concepts/elle-girilen-veri]].

## Kısıtlar

Realtime Database güvenlik kuralları repoda **yok**. `firestore.rules` yalnızca Firestore'u kapsıyor ve `firebase.json` içinde ne `database` ne `firestore` deploy hedefi var — dosya yalnızca FlutterFire yapılandırması taşıyor.

> **Açık soru (2026-07-28):** RTDB kuralları yalnızca Firebase Console'da yaşıyor, sürüm kontrolünde izi yok. Bu iki riski doğuruyor: (a) `cafeteria_menu` ve `ring_schedule` düğümlerinin kim tarafından okunabildiği/yazılabildiği repodan bilinemez, (b) kurallar yanlışlıkla değiştirilirse geri alacak referans yok. Bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].

## Notlar

Üretimde dört hat var: `au_102` ve `au_103`, her biri gidiş/dönüş. `au_103_gidis` hafta içi 72 kalkış içeriyor; sabah yoğun saatte 10 dakika, gün ortası 15-17 dakika aralık.

Hiçbir hatta `stops` alanı girilmemiş — sonucu [[wiki/data/ring-stops]] sayfasında.
