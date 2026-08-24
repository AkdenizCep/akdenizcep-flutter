---
title: 008 — Durak topolojisi asset'te, saatler veritabanında
type: decision
updated: 2026-08-24
status: current
sources:
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/ring/services/stops_service.dart
    sha: 26119cf
  - path: lib/features/ring/services/ring_service.dart
    sha: 26119cf
  - path: lib/features/ring/models/route_key.dart
    sha: 26119cf
---

# 008 — Durak topolojisi asset'te, saatler veritabanında

## Bağlam

[[wiki/decisions/002-realtime-db-firestore-ayrimi]] ring verisinin tamamını
"üniversitenin elle girdiği, seyrek değişen veri" sayıp Realtime Database'e
koymuştu. Uygulamada bunun sonucu şuydu:

- `ring_stops` düğümüne duraklar yer tutucu adlarla (`durak_1`) yüklenmişti
- Hiçbir hattın `stops` dizisi girilmemişti
- [[wiki/decisions/006-durak-bazli-saat-yok]] gereği uydurma veri
  gösterilmediği için durak arayüzünün **tamamı** boştu: harita, en yakın
  durak, favoriler, durak detayı

Yani eksik olan kod değil veriydi ve veri elle girişe bağlı olduğu için aylarca
öyle kaldı. Bkz. [[wiki/concepts/elle-girilen-veri]].

Aynı sırada ANTOBÜS GTFS dökümünden türetilmiş iki dosya elde edildi: hat
çizgileri (`au_hatlar.json`) ve 33 durak (`au_duraklar.json`).

## Karar

Ring verisi **ikiye bölündü**:

| Veri | Kaynak | Gerekçe |
| --- | --- | --- |
| Kalkış saatleri (`weekday` / `weekend`) | RTDB `ring_schedule` | Üniversite güncelliyor, dönemlik değişiyor |
| Durak havuzu, konum, hat üyeliği, güzergâh sırası | `assets/routes/au_duraklar.json` | GTFS türevi topoloji, yılda bir değişir |
| Hat çizgileri, renk, yön etiketi | `assets/routes/au_hatlar.json` | Aynı |

`RingService.getStops()` silindi; `ring_stops` düğümü ve
`ring_schedule.stops` dizileri artık **okunmuyor**.

## Gerekçe

**Değişim hızı, veritabanı seçiminin gerçek ölçütü.** 002 "elle girilen veri"
kategorisini tek bir kutu saymıştı; oysa kalkış saatleri dönem başında
değişirken durak konumları yıllarca sabit kalıyor. Kodda sabit tutmanın bedeli
(uygulama güncellemesi) topolojide düşük, saatlerde kabul edilemez.

**Karşı örnek zaten vardı.** [[wiki/features/map]] kampüs marker'larını
`map_service.dart` içinde `static const` tutuyor ve
[[wiki/concepts/elle-girilen-veri]] bunu "savunulabilir, çünkü bina konumları
ring saatlerinin aksine değişmiyor" diye gerekçelendiriyor. Duraklar da bu
tarafa aittir.

**Veri zenginliği elle girişle taşınamazdı.** `servedBy` ve `stopSequence`
Console'da 33 durak için elle yazılacak bilgi değil; GTFS'te zaten var.

**Çevrimdışı çalışır.** Duraklar ve harita çizgileri ağ olmadan da görünür;
yalnızca saatler gelmez.

## Sonuçları

**Kazanılan:** Durak arayüzü ilk kez çalışıyor. Referans bütünlüğü sorunu
kalmadı — hat üyeliği artık iki düğüm arasında elle kurulan bir bağ değil,
tek dosyada. `directionSummary` gerçek yön adını veriyor ("Meltem Kapısı yönü"),
"Gidiş/Dönüş" fallback'ine düşmüyor.

**Ödenen:**

1. **Durak değişikliği uygulama sürümü gerektiriyor.** Üniversite bir durak
   taşırsa Console'dan düzeltilemez.
2. **İki kaynağı birbirine bağlayan bir köprü var.** RTDB `au_102_gidis` derken
   asset `AU102_0` diyor. Eşleştirme `route_key.dart` içinde tek bir sabitte
   (`kGidisDirectionId = 0`) toplandı ve testlendi.
   > **Varsayım:** `gidis` ekinin `directionId: 0`'a (AÜ102 için
   > "ADLİ TIP → MELTEM KAPISI") karşılık geldiği kabul edildi. Üniversitenin
   > "gidiş" tanımı tersse saatler ters yöne bağlanır; düzeltme tek satırdır.
3. **Ad biçimlendirme koda girdi.** GTFS adları TAMAMI BÜYÜK ve önekli geldiği
   için Türkçe başlık biçimi mantığı yazıldı — Dart'ın kendi casing'i Türkçe
   bilmiyor.

## Kaynak

`firebase/README.md` (durak bölümü kaldırıldı), `duraklar_handoff/`,
`ringlines/PROMPT.md`.
