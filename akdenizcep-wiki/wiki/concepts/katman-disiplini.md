---
title: Katman disiplini
type: concept
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/agent-dokumanlari]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/shared/providers/user_provider.dart
    sha: 089b8e8
---

# Katman disiplini

## Tanım

Projenin mimarisi `Model → Service → Provider → Page` ve her katmanın neye dokunabileceği kesin çizgilerle ayrılmış:

- **Model** saf Dart — Flutter veya Firebase import etmez
- **Service** Firebase'e dokunan tek katman — `ref` veya `BuildContext` görmez
- **Provider** Riverpod'a dokunan tek katman
- **Page** yalnızca UI — `ConsumerWidget` + `ref.watch`, `setState` yok

Kuralın tam metni `DEVELOPMENT.md`'de. Bu sayfa kuralın **kodda ne kadar tutulduğunu** izler.

## Projede nasıl uygulanıyor

Tarama sonucu: kural neredeyse tam tutulmuş. Dokuz feature'ın dokuzunda da Firebase erişimi yalnızca `services/` altında.

**Tespit edilen tek istisna:** `lib/shared/providers/user_provider.dart:24` bir provider dosyasından doğrudan `FirebaseFirestore` koleksiyonuna gidiyor. Karşılık gelen bir `shared/services/user_service.dart` yok.

> **Açık soru:** Bu bilinçli bir kısayol mu, gözden kaçmış bir ihlal mi? `shared/services/` klasörü zaten var (`storage_service.dart`, `location_service.dart`) — desen mevcut, uygulanmamış.

**Görünürdeki ikinci istisna gerçek değil:** [[wiki/features/map]]'in `services/` ve `providers/` klasörleri yok, ama veri kaynağı olmadığı için gerekmiyor. `DEVELOPMENT.md`'nin klasör şeması da map'i böyle gösteriyor.

## Kuralın ödediği bedel

Cross-feature import yasağı, aynı veriyi okuyan feature'ları kendi modellerini yazmaya zorluyor:

- `student-events` koleksiyonu üç modelle temsil ediliyor: `StudentEvent`, `HomeEvent`, `ProfileEventSummary`
- [[wiki/features/profile]] beş veri yoluna dokunuyor ve her biri için kendi özet modelini taşıyor

Bu, bağımlılıkları temiz tutuyor ama şema değişikliğinin etki alanını genişletiyor: `student-events`'e alan eklenirse üç dosya güncellenmeli.

## İlgili sayfalar

[[wiki/decisions/001-clean-architecture-reddi]] · [[wiki/features/profile]] · [[wiki/features/map]] · [[wiki/data/student-events]] · [[wiki/concepts/denormalizasyon]]
