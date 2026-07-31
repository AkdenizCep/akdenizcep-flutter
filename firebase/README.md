# Realtime Database seed dosyaları

Bu klasördeki JSON dosyaları Firebase Console üzerinden elle içe aktarılmak
içindir. Uygulama tarafından okunmaz, derlemeye dahil edilmez.

## ring_stops.seed.json

Ring duraklarının koordinat havuzu. Dosyanın kökü doğrudan durak
anahtarlarıdır (`durak_1`, `durak_2`, …) — `ring_stops` sarmalayıcısı
**yoktur**, çünkü içe aktarma `ring_stops` düğümü seçiliyken yapılır.

> Dosya bir zamanlar `ring_stops` sarmalayıcısıyla geliyordu ama içe aktarma
> talimatı düğümü seçmeyi söylüyordu. Bu çelişki yüzünden duraklar bir kez
> kök düğüme yazıldı ve uygulama onları göremedi. Sarmalayıcıyı eklemeyin.

### İçe aktarma

1. Firebase Console → **Realtime Database** → `akdeniz-cep-36d3f-default-rtdb`
2. Ağaçta **`ring_stops`** düğümüne gel (yoksa üst düğümde kal ve aşağıdaki
   uyarıyı oku)
3. Sağdaki **⋮** menüsü → **JSON içe aktar** → bu dosyayı seç

> **Uyarı:** İçe aktarma seçili düğümün altındaki her şeyi **değiştirir**,
> birleştirmez. Kök düğümde içe aktarırsan `cafeteria_menu` ve
> `ring_schedule` dahil tüm veritabanını silersin. Mutlaka önce
> `ring_stops` düğümünü seç.

### İçe aktarmadan önce

- **Durum:** duraklar `ring_stops` altına yüklendi, ama `name` alanları
  yer tutucu olarak `durak_1` / `durak_2` / `durak_3` kaldı. Bu adlar
  doğrudan uygulamada görünür (durak listesi, harita marker'ı, yön seçici,
  durak detayı) — gerçek durak adlarıyla değiştirilmeli.
- Anahtarlar (`durak_1`, `durak_2`, `durak_3`) geçicidir. İsimler
  belirlendiğinde okunabilir slug'lara çevirmek daha iyi olur
  (`rektorluk`, `ziraat` gibi). Anahtarı değiştirirsen `ring_schedule`
  içindeki `stops` dizilerini de güncellemen gerekir.

### İkinci adım: hatlara bağlama — **yapıldı**

Duraklar tek başına yüklendiğinde durak listesinde hat bilgisi görünmez.
Her hattın `stops` dizisine, güzergah sırasına göre (kalkış → varış) durak
anahtarlarının eklenmesi gerekir. Dört hatta da eklendi (koordinat sırasına
göre, gidiş batıdan doğuya):

```
au_102_gidis / au_103_gidis → ["durak_1", "durak_2", "durak_3"]
au_102_donus / au_103_donus → ["durak_3", "durak_2", "durak_1"]
```

Gerçek güzergah bu sıradan farklıysa dizileri düzeltin. Şema şöyledir:

```json
"ring_schedule": {
  "au102_gidis": {
    "weekday": ["07:30", "08:00"],
    "weekend": ["09:00"],
    "stops": ["durak_1", "durak_2", "durak_3"]
  },
  "au102_donus": {
    "weekday": ["07:45", "08:15"],
    "weekend": ["09:30"],
    "stops": ["durak_3", "durak_2", "durak_1"]
  }
}
```

Koordinatlar batıdan doğuya `durak_1 → durak_2 → durak_3` sırasında; gidiş
yönü bunun tersiyse dizileri ters çevir.

Şema kurallarının tamamı için `DEVELOPMENT.md` → Realtime Database bölümüne
bak.
