---
title: map
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/map/pages/map_page.dart
    sha: ae378bb
---

# map

## Sorumluluk

Kampüs haritası — Google Maps üzerinde statik marker'lar.

## Tükettiği veri

**Hiçbiri.** Firebase'e dokunmuyor. Marker'lar kodda sabit.

## Yapısal istisna

Projedeki **tek eksik katmanlı feature**: yalnızca `pages/` klasörü var. `models/`, `services/`, `providers/` yok.

Bu, katman kuralının ihlali değil — veri kaynağı olmayan bir feature'ın servise ihtiyacı yok. `DEVELOPMENT.md`'nin klasör yapısı bölümü de map'i böyle gösteriyor, yani bilinçli. Bkz. [[wiki/concepts/katman-disiplini]].

## Komşu feature'lar

[[wiki/features/ring]] ile örtüşme: ring de durakları haritada gösteriyor (`stops_map.dart`) ve iki feature aynı `google_maps_flutter` bağımlılığını ayrı ayrı kullanıyor. Kod paylaşımı yok.

## Kararlar

- **Statik marker.** Konumlar veritabanından değil kodda. Karşılaştırma: ring durakları RTDB'den geliyor ve kod değişmeden güncellenebiliyor. Bkz. [[wiki/concepts/elle-girilen-veri]].
- **Kendi sekmesi var.** Shell route'un 5. dalı `/map`.

## Açık sorular

- Kampüs noktaları neden RTDB'de değil? Ring durakları için veriden okuma tercih edilmişken burada kod içinde sabit tutulması tutarsız görünüyor — ama bina konumları ring saatlerinin aksine hiç değişmiyor, yani savunulabilir.
- Ring'in `stops_map` bileşeniyle ortak bir harita bileşeni `shared/components/` altına çıkarılabilir mi?
