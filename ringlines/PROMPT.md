# Claude Code Prompt — AÜ102 / AÜ103 hatlarını Google Maps üzerinde çizdirme

> Aşağıdaki bloğun tamamını Claude Code'a yapıştır. `au_hatlar.json` dosyasını da
> projenin köküne (ya da doğrudan `assets/routes/` altına) kopyalamayı unutma.

---

Mevcut bir Flutter projesine, Antalya ANTOBÜS'ün **AÜ102** ve **AÜ103** otobüs hatlarının
güzergâh çizgilerini Google Maps üzerinde gösteren bir katman eklemeni istiyorum.

## Kapsam

Sadece **hat çizgileri** (polyline). Durak marker'ı, sefer saati, canlı araç konumu,
rota hesaplama YOK — bunları eklemeye çalışma.

## Önce keşif

Kod yazmadan önce projeyi incele ve bana kısaca ne bulduğunu söyle:

1. `pubspec.yaml` — `google_maps_flutter` ekli mi, hangi sürüm? Değilse ekle.
2. Halihazırda bir harita ekranı / `GoogleMap` widget'ı var mı? Varsa çizgileri
   **oraya** entegre et, yeni bir ekran açma. Yoksa `MapScreen` adında yeni bir
   ekran oluştur ve nereden açılacağını bana sor.
3. Android (`android/app/src/main/AndroidManifest.xml`) ve iOS (`ios/Runner/AppDelegate.swift`)
   tarafında Google Maps API anahtarı tanımlı mı? Değilse yapılandırmayı ekle ama
   anahtarı `YOUR_API_KEY` placeholder'ı olarak bırak ve bana söyle.
4. Projenin mevcut mimarisine uy — state yönetimi (Provider/Riverpod/Bloc/setState),
   klasör yapısı, dosya adlandırma ve linter kuralları neyse ona göre yaz.
   Yeni bir state management paketi ekleme.

## Veri

`au_hatlar.json` dosyasını `assets/routes/au_hatlar.json` olarak projeye ekle ve
`pubspec.yaml` içinde asset olarak kaydet.

**Şema** (`schemaVersion: 1`):

```jsonc
{
  "schemaVersion": 1,
  "coordinateOrder": "[latitude, longitude]",   // DİKKAT: GeoJSON değil, lat önce
  "crs": "EPSG:4326 (WGS84)",
  "bounds": { "south": 36.890047, "west": 30.637809,
              "north": 36.900730, "east": 30.662675 },   // 4 hattın tamamını kapsar
  "routes": [
    {
      "id": "AU102_0",                    // benzersiz, PolylineId olarak kullan
      "shortName": "AÜ102",
      "routeId": "01020",                 // GTFS route_id
      "directionId": 0,                   // 0 = gidiş, 1 = dönüş
      "headsign": "ADLİ TIP → MELTEM KAPISI",
      "label": "AÜ102 · Meltem Kapısı yönü",   // kullanıcıya gösterilecek metin
      "shapeId": "010200",                // GTFS shape_id
      "color": "#1565C0",                 // çizgi rengi (hex, # ile)
      "lengthKm": 3.43,
      "pointCount": 27,
      "bounds": { "south": ..., "west": ..., "north": ..., "east": ... },
      "points": [ [36.899728, 30.656373], [36.899679, 30.656358], ... ]
    }
  ]
}
```

Toplam 4 güzergâh var (2 hat × 2 yön), 130 koordinat noktası. Dosya 8 KB.

**Kritik detay:** `points` dizisindeki her eleman `[latitude, longitude]` sırasındadır.
GeoJSON'un `[lon, lat]` sırası DEĞİLDİR. Parse ederken `LatLng(p[0], p[1])` yaz.

## Yapılacaklar

1. **Model** — `RouteShape` (ve `RouteShapeBundle`) sınıfları; `fromJson` ile parse.
   Alanları yukarıdaki şemaya birebir karşılık gelsin. `points` alanını
   `List<LatLng>` olarak tut.
2. **Yükleyici** — `rootBundle.loadString` ile asset'i oku, JSON'u çöz, sonucu
   bir kez yükleyip cache'le (her rebuild'de yeniden parse etme).
3. **Polyline üretimi** — her güzergâh için bir `Polyline`:
   - `polylineId: PolylineId(route.id)`
   - `points: route.points`
   - `color`: JSON'daki hex'ten `Color` üret (`#RRGGBB` → `0xFF` + değer)
   - `width: 5`, `startCap`/`endCap`: `Cap.roundCap`, `jointType: JointType.round`
   - `consumeTapEvents: true` ve `onTap`: alt tarafta `label` + `lengthKm` gösteren
     bir `SnackBar` ya da küçük bir bilgi kartı aç.
4. **Kamera** — harita ilk oluşturulduğunda üstteki kök `bounds` değerine
   `LatLngBounds` + `CameraUpdate.newLatLngBounds(bounds, 40)` ile otomatik sığdır.
   Bunu `onMapCreated` içinde, ilk frame çizildikten sonra çağır (aksi halde
   harita boyutu henüz bilinmediği için exception atabilir).
5. **Aç/kapa kontrolü** — haritanın üstünde, 4 güzergâhı tek tek gösterip
   gizleyebilen kompakt bir katman: her satırda rengin küçük bir örneği + `label`
   + bir `Switch` veya `FilterChip`. Varsayılan: hepsi açık.

## Kabul kriterleri

- `flutter analyze` temiz çalışıyor (yeni uyarı yok).
- Uygulama açıldığında harita Akdeniz Üniversitesi kampüsüne odaklanmış geliyor ve
  4 çizgi de görünüyor.
- Bir çizgiye dokununca hangi hat olduğu görünüyor.
- Katman kontrolünden bir güzergâhı kapatınca çizgi haritadan kalkıyor.
- JSON dosyası değiştirilip yeniden çalıştırıldığında kodda hiçbir değişiklik
  gerekmiyor (hat sayısı, renk, isim hepsi veriden geliyor — hiçbirini koda gömme).

## Bilmen gerekenler

- Geometriler GTFS `shapes.txt`'ten geliyor; **yola oturtulmuş (map-matched) değil**.
  Ardışık noktalar arası mesafe yer yer 500–860 metreye çıkıyor, dolayısıyla çizgi
  bazı virajlarda yolu kesip geçiyor. Bu beklenen bir durum, düzeltmeye çalışma.
- İki hat da aynı iki uçtan geçiyor (Adli Tıp ↔ Meltem Kapısı / Doğu Kapısı), bu
  yüzden güzergâhlar kampüs içinde yer yer üst üste biniyor. Renkler ve yön
  ayrımı bunun için var; çizgileri birleştirmeye veya sadeleştirmeye çalışma.
- Türkçe karakterler (`Ü`, `İ`, `ı`, `ş`, `ğ`) veride mevcut. Dosya UTF-8;
  parse ederken encoding'e dokunma, `utf8.decode` gerekmiyor —
  `rootBundle.loadString` zaten UTF-8 okur.

İşin bitince değiştirdiğin/eklediğin dosyaların listesini ve API anahtarı gibi
benim elle yapmam gereken adımları özetle.
