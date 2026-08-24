# Realtime Database seed dosyaları

Bu klasördeki JSON dosyaları Firebase Console üzerinden elle içe aktarılmak
içindir. Uygulama tarafından okunmaz, derlemeye dahil edilmez.

> **Uyarı:** İçe aktarma seçili düğümün altındaki her şeyi **değiştirir**,
> birleştirmez. Kök düğümde içe aktarırsan `cafeteria_menu` ve `ring_schedule`
> dahil tüm veritabanını silersin. Mutlaka önce hedef düğümü seç.

## Duraklar artık burada değil

`ring_stops.seed.json` **kaldırıldı**. Ring durakları — konum, hat üyeliği ve
güzergâh sırası — uygulamayla birlikte gelen `assets/routes/au_duraklar.json`
dosyasından okunuyor. `ring_stops` düğümü artık uygulama tarafından
**okunmuyor**; Console'da duruyorsa silinebilir.

Nedeni: duraklar GTFS türevi topolojidir, yılda bir değişir ve elle giriş
gerektirmesi durak arayüzünün uzun süre boş kalmasına yol açtı. Aynı gerekçeyle
`ring_schedule` içindeki `stops` dizileri de artık okunmuyor — girili olsalar da
yok sayılırlar, silinebilirler.

Durak verisi değiştiğinde `assets/routes/au_duraklar.json` güncellenir ve yeni
bir uygulama sürümü çıkılır.

## ring_schedule — RTDB'nin tek ring sorumluluğu

Üniversitenin gerçekten güncellediği veri kalkış saatleridir; bu yüzden RTDB'de
kalır. Şema:

```json
"ring_schedule": {
  "au102_gidis": {
    "weekday": ["07:30", "08:00"],
    "weekend": ["09:00"]
  },
  "au102_donus": {
    "weekday": ["07:45", "08:15"],
    "weekend": ["09:30"]
  }
}
```

| Alan | Not |
| --- | --- |
| `weekday` / `weekend` | `HH:mm`, **hattın kalkış noktasından** ayrılış saatleri |
| `stops` | Artık okunmuyor. Bkz. yukarısı. |

Anahtar sözleşmesi `<hatKodu>_<yön>`, yön eki `gidis` veya `donus`. Hat listesi
kodda sabit değildir, bu anahtarlardan türetilir.

`gidis` eki, `assets/routes/au_hatlar.json` içindeki `directionId: 0` ile
eşleşir (AÜ102 için "ADLİ TIP → MELTEM KAPISI"). Eşleştirme
`lib/features/ring/models/route_key.dart` içinde tek bir sabitte durur.

Şema kurallarının tamamı için `DEVELOPMENT.md` → Realtime Database bölümüne bak.
