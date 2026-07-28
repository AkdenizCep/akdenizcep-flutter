---
title: ring
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/realtime-db-json]]"
code_refs:
  - path: lib/features/ring/services/ring_service.dart
    sha: a32558f
  - path: lib/features/ring/models/ring_schedule.dart
    sha: a32558f
  - path: lib/features/ring/models/ring_departures.dart
    sha: e36ca3d
---

# ring

## Sorumluluk

Kampüs ring servisinin kalkış saatlerini ve durak konumlarını göstermek. Uygulamanın **en çok bileşene bölünmüş** feature'ı — 18 bileşen dosyası, iki sayfa (`ring_page`, `ring_stops_page`).

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/ring-schedule]] | okur (stream) |
| [[wiki/data/ring-stops]] | okur (stream) |
| Cihaz konumu | `shared/services/location_service.dart` üzerinden — en yakın durak hesabı |

Firebase'e **hiç yazmıyor**. Tamamen salt okunur bir feature.

## Komşu feature'lar

- **shared** — konum servisi ve provider'ı burada değil `lib/shared/` altında, çünkü kullanımı ring'e özel değil. Katman kuralına uygun.
- [[wiki/features/map]] ile kavramsal örtüşme var (ikisi de Google Maps kullanıyor) ama kod paylaşımı yok.

## Kararlar

- **Hat listesi veriden türetilir.** Kodda sabit hat listesi yok; anahtarlar `ring_schedule` düğümünden okunup `RingSchedule.lineCode` ile gruplanıyor. Üniversite yeni hat eklerse kod değişmeden görünür.
- **Anahtar biçimi ikiliğine savunma.** `au102_gidis` ve `au_103_gidis` biçimleri aynı hatta indirgeniyor — üretim verisindeki tutarsızlığın kodda bıraktığı iz. Ayrıntı: [[wiki/data/ring-schedule]].
- **Durak verisi yoksa uydurma yok.** `stops` girilmemişse yön seçici "Gidiş / Dönüş"e düşüyor, "Yakındaki Duraklar" hiç gösterilmiyor. Bkz. [[wiki/decisions/006-durak-bazli-saat-yok]].
- **Saf hesaplama modeli ayrı.** `ring_departures.dart` Firebase'e bağlı değil — sonraki kalkışların hesabı test edilebilir saf Dart. Projedeki iki test dosyasından ikisi de bu feature'a ait (`test/ring_departures_test.dart`, `test/ring_schedule_test.dart`).

## Açık sorular

- Bugün üretimde `ring_stops` boş — durak bağlı tüm arayüz (harita, en yakın durak, favori duraklar) çalışmıyor. Bekleyen iş [[wiki/data/ring-stops]]'ta adım adım yazılı.
- 18 bileşen tek bir feature için yüksek. Bir kısmı ([[wiki/features/cafeteria]]'daki `soft_segment`, `date_strip` benzerleri) `shared/components/` adayı olabilir.
- Kalkış saatleri hattın **başlangıç** noktasına ait; ara duraklar için varış tahmini yok ve bilinçli olarak gösterilmiyor. Kullanıcının bunu anlayıp anlamadığı ölçülmedi.
