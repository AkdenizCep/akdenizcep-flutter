---
title: 001 — Clean Architecture reddi
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/agent-dokumanlari]]"
---

# 001 — Clean Architecture reddi

## Bağlam

Flutter ekosisteminde yaygın kurumsal desen Clean Architecture: UseCase sınıfları, Repository arayüz/implementasyon ayrımı, DTO ile Entity çifti. Bu proje bir öğrenci ekibi tarafından geliştirilen, tek backend'i Firebase olan bir uygulama.

## Karar

Clean Architecture **kullanılmayacak**. Mimari dört katman: `Model → Service → Provider → Page`.

Açıkça reddedilenler:

- UseCase / Interactor sınıfları
- Repository arayüzü ve implementasyonu ayrımı
- DTO ile Entity ayrımı — model Firestore dokümanından doğrudan map edilir

## Gerekçe

`DEVELOPMENT.md` bunu "pragmatic architecture" olarak adlandırıyor. Çıkarılabilen gerekçeler:

- **Tek veri kaynağı var.** Repository arayüzünün asıl kazancı kaynağı değiştirilebilir kılmaktır. Firebase değiştirilmeyecekse arayüz bedava soyutlama olur.
- **DTO/Entity ayrımı Firestore'da düşük getirili.** Firestore zaten `Map<String, dynamic>` döndürüyor; `fromJson` bu sınırda duruyor.
- **Ekip küçük.** Katman sayısı arttıkça yeni bir özelliğin dokunduğu dosya sayısı artar.

## Sonuçları

**Kazanılan:** Yeni bir feature dört dosyayla ayağa kalkıyor. Bir veri akışını takip etmek dört adım sürüyor.

**Ödenen:** Servisler doğrudan Firebase'e bağlı olduğu için birim testi Firebase emülatörü olmadan yazılamıyor. Projedeki iki test dosyası da ([[wiki/features/ring]]) Firebase'e bağlı olmayan saf hesaplama modelini test ediyor — `ring_departures.dart`. Bu tesadüf değil: test edilebilen tek şey o.

**Sınır nasıl korunuyor:** Repository yerine [[wiki/concepts/katman-disiplini]] kuralları geçmiş. Kural yazılı ve kodda neredeyse tam tutulmuş.

## Kaynak

`DEVELOPMENT.md` → "Mimari: Model / Service / Provider / Pages" bölümü, ilk paragraf. `CLAUDE.md` ve `AGENTS.md` aynı kararı "Not Clean Architecture" başlığıyla tekrarlıyor.
