# raw/ — Ham kaynaklar

Bu klasör wiki'nin **gerçek kaynağıdır**. Claude buradan okur, buraya asla yazmaz.

## Buraya ne girer

Yalnızca **başka hiçbir yerde yaşamayan** içerik:

- `notes/` — karar notları, toplantı özetleri, üniversiteyle yazışmalar, kullanıcı geri bildirimleri, "şunu neden böyle yaptık" yazıları
- `assets/` — ekran görüntüleri, tasarım görselleri, veri dökümleri

## Buraya ne girmez

`DEVELOPMENT.md`, `firestore.rules`, `realtime_db.json`, Dart kodu — bunlar zaten repoda. Kopyalanmazlar; `wiki/sources/` altındaki sayfalar bunlara repo yolu + commit SHA'sı ile referans verir. Kopyalamak ikinci bir gerçek kaynağı yaratır ve bayatlar.

## Nasıl not atarım

`notes/` içine markdown dosyası bırak. Biçim serbest — düzenli olması gerekmiyor, Claude düzenleyecek. Yalnız şu ikisini yaz:

```markdown
# Kısa başlık
Tarih: 2026-07-28

...ham içerik...
```

Sonra sohbette `/wiki-ingest raw/notes/dosya-adi.md` çalıştır.

Dosya adları kebab-case ve tarihli olsun: `2026-07-28-ring-durak-toplantisi.md`.
