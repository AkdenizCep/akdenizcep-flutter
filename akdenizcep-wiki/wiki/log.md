---
title: Günlük
type: log
updated: 2026-07-28
status: current
---

# Günlük

Kronolojik, append-only. En yeni üstte. Girdi biçimi sabittir:
`grep '^## \[' log.md | head -5` son beş girdiyi verir.

## [2026-07-28] setup | Wiki kuruldu ve ilk tohumlama yapıldı

`llm-wiki.md` deseni projeye uygulandı. Şema `../CLAUDE.md`'ye yazıldı, üç operasyon `.claude/commands/` altında slash komutu oldu (`/wiki-ingest`, `/wiki-query`, `/wiki-lint`). `karpathywiki` Obsidian eklentisi devre dışı bırakıldı — tek yazar disiplini.

Tohumlama HEAD `e36ca3d` üzerinde yapıldı; çalışma ağacında commit edilmemiş değişiklikler vardı (`ring/` dosyaları, `DEVELOPMENT.md`, `router.dart`), `code_refs` SHA'ları son commit'leri gösteriyor.

Oluşturulan: 5 kaynak, 9 feature, 11 veri yolu, 5 kavram, 7 karar sayfası + [[wiki/overview]], [[wiki/index]].

Beş bulgu çıktı, hepsi birden fazla dosyanın karşılaştırılmasından: [[wiki/data/board]] kuralsız · [[wiki/data/ring-stops]] yanlış düğümde · [[wiki/features/home]] hızlı erişim kartları bağlı değil · [[wiki/data/cafeteria-ratings]] `avgRating` korumasız · kurallar deploy hattında değil ([[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]]).

## [2026-07-28] ingest | Kod tabanı taraması

`lib/features/*/services/`, `lib/shared/`, `lib/app/router.dart` tarandı; her Firebase yolu okuyan/yazan feature'a bağlandı. Sayfa: [[wiki/sources/kod-tabani]]. Dokuz feature bulundu, dökümanlar sekiz sayıyor — [[wiki/features/profile]] belgelenmemiş.

## [2026-07-28] ingest | realtime_db.json

Üretim RTDB dökümü. `DEVELOPMENT.md` ile dört çelişki işaretlendi. Sayfa: [[wiki/sources/realtime-db-json]]. Dokunulan: [[wiki/data/ring-schedule]], [[wiki/data/ring-stops]], [[wiki/data/cafeteria-menu]], [[wiki/concepts/elle-girilen-veri]], [[wiki/decisions/006-durak-bazli-saat-yok]].

## [2026-07-28] ingest | firestore.rules

Yetkilendirmenin sunucu tarafı. İki kritik bulgu: `board` kuralsız, `avgRating` client'a açık. Sayfa: [[wiki/sources/firestore-rules]]. Dokunulan: sekiz [[wiki/index|data]] sayfası, [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]], [[wiki/concepts/ogrenci-dogrulama]], [[wiki/decisions/003-eposta-domain-kisiti]], [[wiki/decisions/007-kulup-etkinligi-adminuid]].

## [2026-07-28] ingest | CLAUDE.md ve AGENTS.md

Agent yönergeleri. Feature listesi ve Cloud Function ifadesi kodla çelişiyor. Sayfa: [[wiki/sources/agent-dokumanlari]].

## [2026-07-28] ingest | DEVELOPMENT.md

Otoriter mimari dökümanı. Wiki'nin temeli; kopyalanmadı, link verildi. Sayfa: [[wiki/sources/development-md]]. Dokunulan: [[wiki/concepts/katman-disiplini]], [[wiki/decisions/001-clean-architecture-reddi]], [[wiki/decisions/002-realtime-db-firestore-ayrimi]].
