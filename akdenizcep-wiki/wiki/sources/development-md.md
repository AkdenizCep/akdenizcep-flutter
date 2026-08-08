---
title: DEVELOPMENT.md
type: source
updated: 2026-07-28
status: current
sources: []
code_refs:
  - path: DEVELOPMENT.md
    sha: 17e1cc0
---

# Kaynak — DEVELOPMENT.md

## Künye

- **Yol:** `DEVELOPMENT.md` (repo kökü)
- **Tür:** Repo-yerlisi döküman, Türkçe
- **Sahibi:** Proje ekibi, elle yazılmış

## Özet

Projenin **otoriter** mimari dökümanı. Kapsadıkları:

- Proje özeti ve tech stack (Flutter · Firebase · Riverpod)
- Dört katmanlı mimari: `Model → Service → Provider → Page`. Clean Architecture açıkça reddedilmiş — bkz. [[wiki/decisions/001-clean-architecture-reddi]]
- Katman sorumlulukları ve her biri için örnek kod
- Klasör yapısı
- Firestore koleksiyonları ve Realtime DB düğümlerinin şeması
- Ring veri kuralları — hat anahtarı biçimi, durak havuzu, "durak bazlı saat yayınlanmaz" kuralı
- Kimlik doğrulama kuralları
- "Yapılması Gerekenler" / "Kaçınılması Gerekenler" listeleri
- Bağımlılık listesi

## Wiki ile ilişkisi

Bu döküman mimari için tek gerçek kaynağıdır. Wiki onu **kopyalamaz**. Wiki'nin işi, bu dökümanın anlatmadığı şeyi tutmak: kararların gerekçesi, veri yollarının feature'lar arası kullanımı, dökümanın kodla uyuşmadığı yerler.

## Bilinen sapmalar

Bu döküman kodla üç noktada uyuşmuyor. Ayrıntı ilgili sayfalarda:

- Feature listesi 8 feature sayıyor, kodda 9 var — bkz. [[wiki/features/profile]]
- `board` koleksiyonu hiç geçmiyor — bkz. [[wiki/data/board]]
- `feedback` koleksiyonu hiç geçmiyor — bkz. [[wiki/data/feedback]]
- Realtime DB örneği prodüksiyon verisiyle uyuşmuyor — bkz. [[wiki/data/ring-stops]], [[wiki/sources/realtime-db-json]]

## Bu kaynaktan türeyen sayfalar

[[wiki/concepts/katman-disiplini]] · [[wiki/concepts/ogrenci-dogrulama]] · [[wiki/concepts/elle-girilen-veri]] · [[wiki/decisions/001-clean-architecture-reddi]] · [[wiki/decisions/002-realtime-db-firestore-ayrimi]] · [[wiki/decisions/003-eposta-domain-kisiti]] · [[wiki/decisions/006-durak-bazli-saat-yok]] · tüm [[wiki/index|features]] sayfaları
