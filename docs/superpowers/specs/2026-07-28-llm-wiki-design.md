# Akdeniz Cep LLM-Wiki — Tasarım Dokümanı

- **Tarih:** 2026-07-28
- **Baz commit:** `e36ca3d`
- **Kaynak fikir:** `akdenizcep-wiki/llm-wiki.md`
- **Durum:** Onaylandı

## Amaç

`akdenizcep-wiki/` Obsidian vault'unu, `akdenizcep-flutter` projesinin kalıcı ve birikimli bilgi tabanına dönüştürmek. Bilgi her soruda sıfırdan kodu tarayarak yeniden türetilmek yerine bir kez derlenir, sonra güncel tutulur.

Wiki'yi Claude Code yazar ve bakımını yapar. Kullanıcı kaynak sağlar, soru sorar, yönlendirir. Obsidian salt okuma/gezinme aracıdır.

## Kapsam kararları

| Karar | Seçim | Gerekçe |
| --- | --- | --- |
| Wiki neyin bilgi tabanı | Projenin kendisi (kod + kararlar) | Kullanıcı seçimi |
| Kaynaklar | Mevcut proje dökümanları, kod tabanı, karar/toplantı notları | Kullanıcı seçimi. Git geçmişi/PR ingest'i kapsam dışı. |
| Bakımcı | Claude Code, `akdenizcep-wiki/CLAUDE.md` şemasıyla | Kod tabanını okuyabiliyor, ek API key gerekmiyor, çapraz feature bağlantılarını doğru kuruyor |
| Yaklaşım | A — Sentez katmanı | Kodu kopyalamaz; kodun cevaplamadığını biriktirir |

### Kapsam dışı

- qmd veya gömü tabanlı arama motoru — bu ölçekte `index.md` yeterli
- Marp slayt üretimi
- Git geçmişi / PR ingest'i
- `karpathywiki` Obsidian eklentisi — devre dışı bırakılır (tek yazar disiplini)
- Flutter uygulamasına herhangi bir kod değişikliği — bu iş Dart tarafına dokunmaz

## Temel ilke: tek gerçek kaynağı

`DEVELOPMENT.md` mimari için otoriter kalır. Wiki onu **kopyalamaz, link verir**. Wiki yalnızca kodun ve mevcut dökümanların *cevaplamadığı* soruları sahiplenir:

- Bu feature neden böyle yapıldı, hangi alternatif elendi
- Hangi feature hangi veri yolunu okuyor/yazıyor (bugün sekiz feature'a dağılmış bilgi)
- Hangi iddia hangi kaynağa dayanıyor, ne zaman doğrulandı
- Neresi çelişiyor, neresi bayat

## Mimari

### Üç katman

**1. Ham kaynaklar — `akdenizcep-wiki/raw/`**

Salt okunur. Yalnızca *başka hiçbir yerde yaşamayan* içerik girer:

```
raw/
├── notes/    # karar & toplantı notları, üniversiteyle yazışmalar, kullanıcı geri bildirimi
├── assets/   # görseller, ekran görüntüleri
└── README.md # buraya nasıl not atılır
```

Repo-yerlisi kaynaklar (`DEVELOPMENT.md`, `firestore.rules`, `realtime_db.json`, Dart kodu) **kopyalanmaz**. Onlar için `wiki/sources/` altındaki sayfa repo yolunu ve ingest anındaki commit SHA'sını işaret eder.

**2. Wiki — `akdenizcep-wiki/wiki/`**

```
wiki/
├── index.md       # içerik kataloğu: her sayfa + tek satır özet, kategoriye göre
├── log.md         # kronolojik, append-only: ## [YYYY-MM-DD] ingest|query|lint | Başlık
├── overview.md    # projenin evrilen sentezi, tek sayfa
├── features/      # 8 sayfa: auth, board, cafeteria, community, home, map, ring, student_events
├── data/          # Firestore koleksiyonları + Realtime DB düğümleri
├── concepts/      # kesişen kavramlar
├── decisions/     # ADR'ler
└── sources/       # provenance: her ingest edilmiş kaynak için bir sayfa
```

`data/` bu wiki'nin en yüksek değerli parçası: her koleksiyon/düğüm sayfası şemayı ve **okuyan/yazan feature tablosunu** tutar. Bu bilgi bugün tek bir yerde mevcut değil.

**3. Şema — `akdenizcep-wiki/CLAUDE.md`**

Claude Code'u disiplinli bir wiki bakımcısı yapan konfigürasyon dosyası. İçeriği: klasör düzeni, sayfa tipleri ve şablonları, frontmatter sözleşmesi, üç operasyonun adım adım iş akışı, yazım kuralları (Türkçe, emoji yok, iddia → kaynak zorunluluğu), "kodu kopyalama" kuralı.

Kök `CLAUDE.md`'ye wiki'yi işaret eden bir satır eklenir.

### Frontmatter sözleşmesi

Her wiki sayfasında:

```yaml
---
title: Ring
type: feature          # feature | data | concept | decision | source | overview
updated: 2026-07-28
status: current        # current | stale | draft
sources:
  - "[[sources/development-md]]"
code_refs:
  - path: lib/features/ring/services/ring_service.dart
    sha: e36ca3d
---
```

`code_refs[].sha` bayatlığın ölçüldüğü mekanizmadır: lint, o dosyaların kaydedilen SHA'dan beri değişip değişmediğine bakar.

### Sayfa tipleri ve zorunlu bölümler

- **feature** — Sorumluluk · Tükettiği veri yolları · Komşu feature'lar · Kararlar · Açık sorular
- **data** — Yol · Şema · Okuyanlar/Yazanlar tablosu · Kısıtlar (güvenlik kuralları) · Notlar
- **concept** — Tanım · Projede nasıl uygulanıyor · İlgili sayfalar
- **decision** — Bağlam · Karar · Gerekçe · Sonuçları · Kaynak
- **source** — Künye (yol + SHA veya raw/ yolu) · Özet · Bu kaynaktan türeyen sayfalar

## Operasyonlar

Üçü de `.claude/commands/` altında slash komutu olarak yaşar.

### `/wiki-ingest <kaynak>`

1. Kaynağı oku
2. Ana çıkarımları kullanıcıyla konuş
3. `wiki/sources/` altına özet sayfası yaz
4. Etkilenen `features/`, `data/`, `concepts/`, `decisions/` sayfalarını güncelle
5. Çapraz linkleri kur
6. `index.md` ve `log.md` güncelle

**Çelişki kuralı:** Yeni bilgi mevcut bir iddiayla çelişiyorsa sessizce üzerine yazılmaz. İlgili sayfaya şu blok eklenir ve kullanıcıya bildirilir:

```markdown
> **Çelişki (2026-07-28):** [[sources/x]] şunu söylüyor …, oysa [[sources/y]] … diyordu. Çözülmedi.
```

### `/wiki-query <soru>`

Önce `index.md`, sonra ilgili sayfalar, gerekirse kod. Cevap daima kaynak göstererek verilir. Cevap kalıcı değer taşıyorsa kullanıcıya "wiki'ye sayfa olarak dosyalayayım mı?" diye sorulur — keşifler sohbet geçmişinde kaybolmaz.

### `/wiki-lint`

Sağlık taraması, rapor üretir, düzeltmeyi kullanıcı onaylar:

1. `code_refs` SHA'ları `HEAD`'e karşı diff'lenir → değişmiş dosyaya dayanan sayfa `status: stale`
2. Yetim sayfalar (gelen link yok)
3. Kırık `[[link]]`'ler
4. Sayfalar arası çelişkiler
5. Sık geçen ama kendi sayfası olmayan kavramlar

## İlk tohumlama

Kurulum boş iskelet bırakmaz. Teslim edilecek içerik:

| Çıktı | Adet | Kaynak |
| --- | --- | --- |
| `sources/` sayfası | 4 | `DEVELOPMENT.md`, `CLAUDE.md`+`AGENTS.md`, `firestore.rules`, `realtime_db.json` |
| `features/` sayfası | 8 | `lib/features/*` taraması |
| `data/` sayfası | Firestore koleksiyonları + Realtime DB düğümleri kadar | `firestore.rules`, `realtime_db.json`, servis katmanı |
| `decisions/` sayfası | 5-8 | Koddan ve kurallardan okunabilen gerçek kararlar |
| `concepts/` sayfası | 4-6 | Kesişen kavramlar |
| `overview.md`, `index.md`, `log.md` | 3 | Yukarıdakilerin sentezi |

`raw/notes/` boş başlar — kullanıcının besleyeceği taraf, `README.md` ile nasıl not atılacağı anlatılır.

## Doğrulama

1. `/wiki-lint` çalıştırılır → kırık link yok, yetim sayfa yok
2. Her `[[link]]` hedefinin var olduğu doğrulanır
3. Her `code_refs.path`'in diskte var olduğu doğrulanır
4. `flutter analyze` temiz kalır (wiki repo içinde yaşıyor; Dart tarafına bulaşmadığı teyit edilir)
5. `akdenizcep-wiki/` git'e commit edilir

## Riskler

| Risk | Azaltma |
| --- | --- |
| Wiki `DEVELOPMENT.md`'yi kopyalar, iki gerçek doğar | Şemada açık "kopyalama, link ver" kuralı; feature sayfalarında kod yapısı bölümü yok |
| Kod değişince wiki bayatlar | `code_refs` + SHA damgası, `/wiki-lint` ile ölçülür |
| İki yazar (eklenti + Claude) format çatışması | `karpathywiki` devre dışı bırakılır |
| Vault Obsidian ayarlarıyla repo'yu kirletir | `.obsidian/workspace.json` gitignore'a alınır (makine-yerel durum) |
