---
title: realtime_db.json
type: source
updated: 2026-07-28
status: current
sources: []
code_refs:
  - path: realtime_db.json
    sha: 17e1cc0
  - path: firebase/README.md
    sha: e36ca3d
  - path: firebase/ring_stops.seed.json
    sha: e36ca3d
---

# Kaynak — realtime_db.json

## Künye

- **Yol:** `realtime_db.json` (repo kökü)
- **Tür:** Realtime Database içerik dökümü. Uygulama tarafından okunmaz, derlemeye girmez — üniversitenin elle girdiği verinin repo içindeki yansıması.
- **Kardeş dosyalar:** `firebase/ring_stops.seed.json` (Console'dan elle içe aktarılacak durak havuzu) ve `firebase/README.md` (içe aktarma yönergesi)

## Özet

İki tür veri:

- **Durak düğümleri** — `durak_1`, `durak_2`, `durak_3`, her biri `name` / `lat` / `lng`
- **`ring_schedule`** — dört hat anahtarı: `au_103_gidis`, `au_103_donus`, `au_102_gidis`, `au_102_donus`. Her biri `weekday` ve `weekend` kalkış saati dizileri.

Saat sayıları gerçekçi: `au_103_gidis` hafta içi 72 kalkış, hafta sonu 37. Sabah 08:00–10:30 arası 10 dakikalık, gün ortası 15-17 dakikalık aralıklar.

## Çelişkiler

> **Çelişki (2026-07-28):** Bu dosya ile `DEVELOPMENT.md` → Realtime Database bölümü üç noktada uyuşmuyor:
>
> 1. **Durak konumu.** Duraklar burada **kök düğümde** (`durak_1`, `durak_2`, `durak_3`). `DEVELOPMENT.md` ve `RingService.getStops()` bunları `ring_stops` altında bekliyor. Kod bugün hiçbir durak bulamıyor.
> 2. **Hat anahtarı biçimi.** Burada `au_103_gidis`; `DEVELOPMENT.md` `au102_gidis` diyor. `RingSchedule.lineCode` her iki biçimi de kabul edecek şekilde yazılmış, yani kod bu ikiliği zaten görmüş.
> 3. **`stops` dizisi yok.** Hiçbir hatta `stops` alanı yok. `DEVELOPMENT.md` bunun opsiyonel olduğunu ve girilmediğinde arayüzün "Gidiş / Dönüş"e düşeceğini söylüyor — yani bugün üretimde yön seçici gerçek durak adı göstermiyor.
> 4. **`cafeteria_menu` yok.** `CafeteriaService.getMenu()` bu düğümü okuyor, dökümde hiç yok.
>
> `firebase/README.md` 1 ve 3'ün bilinen ve planlanmış olduğunu gösteriyor: durak isimleri henüz `__DOLDUR__`, anahtarların slug'a çevrilmesi ve `stops` dizilerinin bağlanması bekleyen iş. 4 çözülmedi.

## Bu kaynaktan türeyen sayfalar

[[wiki/data/ring-schedule]] · [[wiki/data/ring-stops]] · [[wiki/data/cafeteria-menu]] · [[wiki/features/ring]] · [[wiki/features/cafeteria]] · [[wiki/concepts/elle-girilen-veri]] · [[wiki/decisions/002-realtime-db-firestore-ayrimi]] · [[wiki/decisions/006-durak-bazli-saat-yok]]
