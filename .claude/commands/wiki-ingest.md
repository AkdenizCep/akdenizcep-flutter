---
description: Bir kaynağı akdenizcep-wiki'ye ingest et
argument-hint: <kaynak yolu veya konu>
---

`akdenizcep-wiki/CLAUDE.md` şemasını oku ve ona uy. Ardından şu kaynağı ingest et:

**$ARGUMENTS**

Adımlar:

1. Kaynağı oku. Yol verilmediyse kullanıcıya ne ingest edeceğini sor.
2. Ana çıkarımları kullanıcıyla konuş — neyi vurgulamak istediğini sor. Onay almadan yazmaya başlama.
3. `akdenizcep-wiki/wiki/sources/` altına özet sayfası yaz. Kaynak repo-yerlisiyse künyeye repo yolunu ve `git log -1 --format=%h -- <path>` ile bulduğun SHA'yı koy.
4. Etkilenen `features/`, `data/`, `concepts/`, `decisions/` sayfalarını güncelle. Tek kaynak 10-15 sayfaya dokunabilir.
5. Çapraz linkleri kur. Çelişki varsa şemadaki çelişki bloğunu ekle ve kullanıcıya bildir — sessizce üzerine yazma.
6. `index.md` ve `log.md` güncelle.

Sonunda dokunulan sayfaların listesini ve varsa çelişkileri raporla.
