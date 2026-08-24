---
title: ring durakları
type: data
updated: 2026-08-24
status: current
sources:
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/ring/services/stops_service.dart
    sha: 26119cf
  - path: lib/features/ring/models/ring_stop.dart
    sha: 26119cf
  - path: assets/routes/au_duraklar.json
    sha: 26119cf
  - path: firebase/README.md
    sha: 26119cf
---

# ring durakları

## Yol

**Asset** · `assets/routes/au_duraklar.json`

Realtime Database `ring_stops` düğümü **artık okunmuyor**. Taşımanın gerekçesi:
[[wiki/decisions/008-durak-topolojisi-asset]].

## Şema

```jsonc
{
  "schemaVersion": 1,
  "coordinateOrder": "[latitude, longitude]",
  "stopCount": 33,
  "serviceRecordCount": 40,
  "bounds": { "south": ..., "west": ..., "north": ..., "east": ... },
  "stops": [
    {
      "stopId": "10955",                                  // GTFS stop_id
      "name": "AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE",
      "lat": 36.895412, "lon": 30.654175,
      "isTransfer": false,
      "routeCount": 1,
      "servedBy": [
        {
          "routeShapeId": "AU102_1",                      // au_hatlar.json ile eşleşir
          "shortName": "AÜ102",
          "directionId": 1,
          "stopSequence": 8,
          "color": "#64B5F6",
          "label": "AÜ102 · Adli Tıp yönü"
        }
      ]
    }
  ]
}
```

| Alan | Not |
| --- | --- |
| `servedBy` | "Bu duraktan hangi hatlar geçiyor" artık hesaplanmıyor, veride duruyor |
| `stopSequence` | Güzergâhtaki sıra. Hiç girilmemiş `ring_schedule.stops` dizisinin karşılığı |
| `isTransfer` | Birden fazla hat geçiyor. 33 duraktan 6'sı |

33 durak, 40 hizmet kaydı. Aynı adın birden çok kaydı olabilir
(`EDEBİYAT FAKÜLTESİ-1` / `-2`) — bunlar yolun iki yakasındaki **ayrı fiziksel
duraklardır**, birleştirilmez; kullanıcı doğru tarafta beklemelidir.

> `AU102_0` ve `AU103_0` için `stopSequence` 1'den değil **2'den** başlar:
> hattın gerçek kalkış durağı (ADLİ TIP) kampüs dışında kaldığı için bu veri
> setinde yok. Kalkış noktasının adı yalnızca `au_hatlar.json`'daki `headsign`
> alanından okunabilir.

## Okuyanlar / Yazanlar

| Feature | İşlem | Nerede |
| --- | --- | --- |
| [[wiki/features/ring]] | okur (asset, bir kez) | `stops_service.dart` |

Yazan yok. Veri değiştiğinde asset güncellenir ve yeni sürüm çıkılır.

## Kısıtlar

- **Adlar TAMAMI BÜYÜK HARF ve "AKDENİZ ÜNİVERSİTESİ" önekli geliyor.** Arayüzde
  gösterilmeden önce kodda başlık biçimine çevrilir. Dart'ın `toLowerCase()`'i
  Türkçe bilmediği için (`I → i`, `İ → i̇`) özel bir eşleme gerekti:
  `lib/features/ring/models/turkish_text.dart`.
- Veride iki ad ASCII `I` ile yazılmış (`Iktisadi ve Idari`); bu bir biçim
  sorunu değil yazım hatasıdır ve adı adına düzeltilir.
- Şema doğrulaması yok, ama artık **elle giriş de yok** — dosya derlemeye dahil,
  testler gerçek asset'i okuyor (`test/ring_stop_test.dart`).

## Notlar

Bu sayfa daha önce "üretimde yanlış düğümde — bugün boş" durumunu anlatıyordu.
Duraklar `ring_stops` düğümüne yer tutucu adlarla (`durak_1`) yüklenmiş, hiçbir
hattın `stops` dizisi girilmemişti; sonuç olarak harita, en yakın durak, favori
duraklar ve durak detayı bütünüyle boş kalıyordu. Bu durum
[[wiki/concepts/elle-girilen-veri]]'nin en somut bedeliydi ve taşımanın
doğrudan sebebidir.

İlgili: [[wiki/data/ring-schedule]] · [[wiki/decisions/006-durak-bazli-saat-yok]]
