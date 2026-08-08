# Akdeniz Cep Wiki — Şema

Bu dosya, Claude Code'u bu vault'ta **disiplinli bir wiki bakımcısı** yapar. Bu klasördeki herhangi bir dosyaya dokunmadan önce buradaki kuralları uygula.

Fikrin kaynağı: `llm-wiki.md`. Tasarım kararları: `../docs/superpowers/specs/2026-07-28-llm-wiki-design.md`.

## Bu wiki ne için var

`akdenizcep-flutter` projesinin kalıcı, birikimli bilgi tabanı. Amaç: bilgiyi her soruda kodu baştan tarayarak yeniden türetmek yerine bir kez derleyip **güncel tutmak**.

Wiki'yi **sen** (Claude Code) yazarsın. Kullanıcı kaynak sağlar, soru sorar, yönlendirir. Obsidian salt gezinme aracıdır.

## En önemli kural: kodu kopyalama

`../DEVELOPMENT.md` mimari için **otoriter**. Wiki onu kopyalamaz, **link verir**.

Wiki yalnızca kodun ve mevcut dökümanların *cevaplamadığı* soruları sahiplenir:

- Bu feature neden böyle yapıldı, hangi alternatif elendi
- Hangi feature hangi veri yolunu okuyor/yazıyor
- Hangi iddia hangi kaynağa dayanıyor, ne zaman doğrulandı
- Neresi çelişiyor, neresi bayat

Bir sayfaya "şu klasörde şu dosyalar var" ya da "model `fromJson` içerir" yazacaksan **yazma** — o bilgi kodda ve `DEVELOPMENT.md`'de zaten var, buraya yazılırsa bayatlar.

## Klasör düzeni

```
raw/            # ham kaynaklar, salt okunur, ASLA düzenleme
  notes/        # karar & toplantı notları, yazışmalar, geri bildirim
  assets/       # görseller
wiki/
  index.md      # içerik kataloğu
  log.md        # kronolojik, append-only
  overview.md   # projenin evrilen sentezi
  features/     # feature başına bir sayfa
  data/         # Firestore koleksiyonu / RTDB düğümü başına bir sayfa
  concepts/     # kesişen kavramlar
  decisions/    # ADR'ler
  sources/      # provenance: ingest edilmiş her kaynak için bir sayfa
```

Repo-yerlisi kaynaklar (`DEVELOPMENT.md`, `firestore.rules`, `realtime_db.json`, Dart kodu) `raw/` içine **kopyalanmaz**. Onlar için `sources/` sayfası repo yolunu ve ingest anındaki commit SHA'sını işaret eder.

## Frontmatter sözleşmesi

Her wiki sayfasında zorunlu:

```yaml
---
title: Ring
type: feature          # feature | data | concept | decision | source | overview | index | log
updated: 2026-07-28
status: current        # current | stale | draft
sources:
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: lib/features/ring/services/ring_service.dart
    sha: e36ca3d
---
```

- `code_refs` yolları **repo kökünden** görelidir (`lib/...`), vault'tan değil.
- `sha` = o iddianın doğrulandığı andaki commit. Bayatlık buradan ölçülür.
- `code_refs` yalnızca gerçekten kod okunarak yazılmış sayfalarda bulunur.

## Sayfa tipleri ve zorunlu bölümler

| Tip | Bölümler |
| --- | --- |
| `feature` | Sorumluluk · Tükettiği veri · Komşu feature'lar · Kararlar · Açık sorular |
| `data` | Yol · Şema · Okuyanlar / Yazanlar · Kısıtlar · Notlar |
| `concept` | Tanım · Projede nasıl uygulanıyor · İlgili sayfalar |
| `decision` | Bağlam · Karar · Gerekçe · Sonuçları · Kaynak |
| `source` | Künye · Özet · Bu kaynaktan türeyen sayfalar |

## Yazım kuralları

- **Dil Türkçe.** Kod tanımlayıcıları (`avgRating`, `student-events`) İngilizce kalır.
- **Emoji yok.**
- **Her iddia kaynaklı.** Bir cümle koddan geliyorsa `code_refs`'e dosyayı ekle; bir dökümandan geliyorsa `[[sources/...]]` linki ver. Kaynağı olmayan iddia yazma.
- **Çapraz link cömertçe.** Başka bir sayfada karşılığı olan her kavram `[[...]]` ile bağlanır. Henüz var olmayan bir sayfaya link vermek serbesttir — yazılması gerekeni işaretler.
- **Link biçimi: vault köküne göre tam yol.** `[[wiki/features/ring]]` — `[[features/ring]]` **değil**. Obsidian vault kökü `akdenizcep-wiki/`, yani `wiki/` öneki zorunlu. Ayrıca `board.md` hem `features/` hem `data/` altında olduğu için yalnız dosya adı (`[[board]]`) da yetmez, belirsiz kalır. Yanlış biçimde link verilirse Obsidian'da tıklandığında vault kökünde boş bir dosya oluşur.
- **Spekülasyon işaretlenir.** Emin olmadığın çıkarımı `> **Varsayım:**` bloğuyla ayır.

## Çelişki kuralı

Yeni bilgi mevcut bir iddiayla çelişiyorsa **sessizce üzerine yazma**. İlgili sayfaya şu bloğu ekle ve kullanıcıya söyle:

```markdown
> **Çelişki (2026-07-28):** [[wiki/sources/x]] şunu söylüyor …, oysa [[wiki/sources/y]] … diyordu. Çözülmedi.
```

Çelişki ancak kullanıcı hangi tarafın doğru olduğunu söyleyince silinir; o zaman yerine bir `[[decisions/...]]` sayfası geçer.

## Operasyonlar

### Ingest — `/wiki-ingest <kaynak>`

1. Kaynağı oku.
2. Ana çıkarımları kullanıcıyla konuş, onun neyi vurgulamak istediğini sor.
3. `wiki/sources/` altına özet sayfası yaz.
4. Etkilenen `features/`, `data/`, `concepts/`, `decisions/` sayfalarını güncelle. Tek bir kaynak 10-15 sayfaya dokunabilir — bu normaldir.
5. Çapraz linkleri kur, çelişkileri işaretle.
6. `index.md` ve `log.md` güncelle.

### Query — `/wiki-query <soru>`

1. Önce `index.md`, sonra ilgili sayfalar. Wiki yetmezse kod.
2. Cevap daima kaynak göstererek verilir.
3. Cevap kalıcı değer taşıyorsa kullanıcıya "wiki'ye sayfa olarak dosyalayayım mı?" diye sor. Keşifler sohbet geçmişinde kaybolmamalı.

### Lint — `/wiki-lint`

1. Her `code_refs` girdisi için: `git log -1 --format=%h -- <path>` ile dosyanın son commit'ine bak. Kayıtlı `sha`'dan sonra değişmişse sayfayı `status: stale` yap ve rapora ekle.
2. Kırık `[[link]]`'ler — hedef dosya yok.
3. Yetim sayfalar — hiçbir sayfadan link almıyor (`index.md` sayılmaz).
4. Sayfalar arası çelişkiler.
5. Sık geçen ama kendi sayfası olmayan kavramlar.

Rapor üret, düzeltmeyi kullanıcı onaylasın. Kendiliğinden toplu düzeltme yapma.

## index.md ve log.md

**index.md** içerik odaklıdır: kategoriye göre gruplanmış, her sayfa için link + tek satır özet. Her ingest'te güncellenir.

**log.md** kronolojiktir, append-only, en yeni üstte. Girdi biçimi sabittir ki `grep '^## \[' log.md | head -5` çalışsın:

```markdown
## [2026-07-28] ingest | firestore.rules
Neyin değiştiğinin bir-iki cümlelik özeti. Dokunulan sayfalar: [[wiki/data/board]], [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].
```

Tip alanı: `ingest` | `query` | `lint` | `setup`.

## Dokunma

- `raw/` altındaki hiçbir dosyayı değiştirme.
- `.obsidian/` — kullanıcının arayüz ayarları.
- `llm-wiki.md` — orijinal fikir dosyası, referans.
- Bu vault'tan Flutter koduna hiçbir değişiklik yapma. Wiki kodu anlatır, kodu yazmaz.
