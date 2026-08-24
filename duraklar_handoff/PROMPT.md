# Claude Code Prompt — AÜ102 / AÜ103 duraklarını haritaya ekleme

> Bu, hat çizgileri prompt'unun devamıdır. Aşağıdaki bloğun tamamını Claude Code'a
> yapıştır ve `au_duraklar.json` dosyasını da ver.
> (Çizgiler henüz çizilmediyse önce onu tamamlat — bu prompt `au_hatlar.json`'daki
> `routeShapeId` değerlerine bağlanıyor.)

---

Daha önce AÜ102 ve AÜ103 hatlarının güzergâh çizgilerini Google Maps üzerine
çizmiştin. Şimdi aynı haritaya **durakları** ekleyeceksin.

## Kapsam

Sadece durak marker'ları ve bunların hat filtresiyle uyumlu çalışması.
Sefer saati, canlı araç konumu, "en yakın durak" hesabı, yol tarifi YOK.

## Önce keşif

Kod yazmadan önce mevcut harita implementasyonunu oku ve bana kısaca özetle:
polyline'ları hangi dosyada üretiyorsun, hat aç/kapa state'i nerede tutuluyor,
`GoogleMap` widget'ı hangi ekranda. Durak katmanını **aynı state'e** bağlayacaksın —
paralel ikinci bir sistem kurma.

## Veri

`au_duraklar.json` dosyasını `assets/routes/au_duraklar.json` olarak ekle ve
`pubspec.yaml`'a kaydet.

**Şema** (`schemaVersion: 1`):

```jsonc
{
  "schemaVersion": 1,
  "coordinateOrder": "[latitude, longitude]",
  "stopCount": 33,
  "serviceRecordCount": 40,       // 33 durak, 40 hat-durak ilişkisi
  "bounds": { "south": ..., "west": ..., "north": ..., "east": ... },
  "stops": [
    {
      "stopId": "14373",                                  // GTFS stop_id, benzersiz
      "name": "AKDENİZ ÜNİVERSİTESİ DOĞU KAPISI GİRİŞİ",
      "lat": 36.892690,
      "lon": 30.662309,
      "isTransfer": true,          // birden fazla HAT (yön değil) buradan geçiyor
      "routeCount": 2,
      "servedBy": [                // bu durağın hizmet verdiği güzergâhlar
        {
          "routeShapeId": "AU102_1",   // au_hatlar.json'daki route.id ile birebir eşleşir
          "shortName": "AÜ102",
          "directionId": 1,
          "stopSequence": 1,           // o güzergâhtaki sıra numarası
          "color": "#64B5F6",
          "label": "AÜ102 · Adli Tıp yönü"
        }
        // ... aynı durak birden fazla güzergâhta olabilir
      ]
    }
  ]
}
```

**Kritik detay:** Duraklar fiziksel konuma göre tekilleştirilmiştir. 33 durak
kaydı var ama toplam 40 hat-durak ilişkisi — 6 durak iki hatta birden hizmet
veriyor. Her durak için **tek marker** üret, hangi hatlara ait olduğunu `servedBy`
üzerinden çöz. Aynı koordinata iki marker koyma.

## Yapılacaklar

1. **Model** — `BusStop` ve `StopService` sınıfları; `fromJson` ile parse.
   `au_hatlar.json` için yazdığın yükleyici deseninin aynısını kullan.

2. **Marker ikonu** — `dart:ui` ile Canvas üzerine çizip `BitmapDescriptor`'a
   dönüştür (`toImage` → `toByteData` → `BitmapDescriptor.bytes`):
   - Yaklaşık 14 logical px çapında dolu daire, çevresinde 2 px beyaz kenarlık,
     altında hafif bir gölge.
   - `MediaQuery.devicePixelRatio` ile ölçekle, yoksa yüksek yoğunluklu
     ekranlarda bulanık çıkar.
   - Renk: durak tek hatta hizmet veriyorsa `servedBy[0].color`. `isTransfer: true`
     ise dolgu beyaz, kenarlık koyu gri (#37474F) olsun — aktarma noktası böyle
     ayırt edilir.
   - İkonları **bir kez üret ve cache'le** (renk başına bir tane, ~5 varyant).
     Her `build` içinde yeniden çizme; 33 marker için async ikon üretimini
     tekrarlamak gözle görülür takılma yaratır.
   - `anchor: Offset(0.5, 0.5)` ver — daire marker'ın merkezi koordinatta olmalı,
     pin gibi ucu değil.

3. **Filtre uyumu** — mevcut hat aç/kapa kontrolü durakları da yönetsin:
   bir durak, `servedBy` içindeki güzergâhlardan **en az biri** görünür durumdaysa
   haritada olsun; hepsi kapalıysa kalksın.

4. **Dokunma davranışı** — marker'a dokununca `showModalBottomSheet` ile küçük bir
   kart aç: durak adı, `stopId`, ve `servedBy` içindeki her güzergâh için bir satır
   (renk örneği + `label` + "N. durak" şeklinde `stopSequence`).
   `InfoWindow` kullanma — üç satırlık içerik için yetersiz ve stillenemiyor.

5. **Zoom eşiği** — duraklar sadece `zoom >= 14` iken görünsün, daha uzakta
   sadece çizgiler kalsın. `onCameraIdle` ile zoom'u oku ve marker setini
   güncelle; `onCameraMove` içinde `setState` çağırma, her frame'de rebuild eder.

## Kabul kriterleri

- `flutter analyze` temiz.
- Haritada 33 marker var, 40 değil. Aynı koordinatta çift marker yok.
- Bir hattı kapatınca sadece o hatta ait duraklar kalkıyor; aktarma durakları
  diğer hat açık kaldığı sürece haritada kalmaya devam ediyor.
- Uzaklaşınca (zoom < 14) marker'lar kayboluyor, çizgiler kalıyor.
- Marker'a dokununca alttan hat bilgisi kartı açılıyor.
- Yeni bir durak JSON'a eklendiğinde kodda değişiklik gerekmiyor.

## Bilmen gerekenler

- **Duraklar çok yakın.** En yakın iki durak 15 metre arayla
  (ENFORMATİK BÖLÜM BAŞKANLIĞI-1 ve -2 — yolun iki yakası). 33 durağın altısı
  birbirine 35 metreden yakın. Bu yüzden marker boyutunu büyütme ve kesinlikle
  marker clustering ekleme; kampüs ölçeğinde cluster her şeyi tek baloncuğa
  toplar ve harita işe yaramaz hale gelir.
- **`-1` / `-2` son ekleri gerçek.** "MÜHENDİSLİK FAKÜLTESİ-1" ve "-2" aynı
  durağın iki yönü değil, GTFS'te ayrı `stop_id`'ye sahip iki ayrı fiziksel
  durak. Bunları isme bakıp birleştirme.
- **Sıra numaralarında boşluk var.** `stopSequence` bazı güzergâhlarda 2'den
  başlıyor veya ortada bir numara atlıyor (kaynak GTFS'te terminal duraklar
  `stops.txt`'e tanımlanmamış). Bu bir veri hatası değil, olduğu gibi göster;
  `stopSequence`'ı dizi indeksi olarak kullanma, sadece etiket olarak yaz.
- Türkçe karakterler veride mevcut, dosya UTF-8. `rootBundle.loadString`
  zaten UTF-8 okur, ek dönüşüm yapma.

İşin bitince değiştirdiğin/eklediğin dosyaların listesini ver.
