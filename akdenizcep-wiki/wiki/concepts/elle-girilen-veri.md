---
title: Elle girilen veri
type: concept
updated: 2026-08-24
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/firestore-rules]]"
---

# Elle girilen veri

## Tanım

Uygulamadaki içeriğin bir kısmı öğrenciler tarafından değil, **Firebase Console'dan elle** giriliyor. Bu veri için ortak özellikler: uygulama yalnızca okur, yazma izni herkese kapalıdır, ve veri kod değişmeden güncellenebilir.

Bu ayrım, "neden bu koleksiyonun create izni yok" sorusunun cevabıdır.

## Projede nasıl uygulanıyor

| Veri | Nerede | Kim girer | Yazma izni |
| --- | --- | --- | --- |
| [[wiki/data/cafeteria-menu]] | RTDB | Üniversite | Uygulamadan yok |
| [[wiki/data/ring-schedule]] | RTDB | Üniversite | Uygulamadan yok |
| [[wiki/data/announcements]] | Firestore | Ekip | `allow write: if false` |
| [[wiki/data/clubs]] | Firestore | Ekip | `create`/`delete` kapalı, yalnızca `followerCount` güncellenebilir |

Buna karşılık öğrencinin ürettiği veri — [[wiki/data/student-events]], [[wiki/data/board]], [[wiki/data/cafeteria-ratings]], [[wiki/data/feedback]] — Firestore'da ve yazma akışı uygulamada var.

## Tasarımın getirisi

**Veri kodu belirlemez.** Ring hat listesi kodda sabit değil, `ring_schedule` anahtarlarından türetiliyor. Üniversite yeni hat eklerse uygulama güncellemesi gerekmiyor. Aynı şekilde `mealType` anahtarları da veriden geliyor.

Karşı örnek [[wiki/features/map]]: kampüs marker'ları kodda sabit. Savunulabilir, çünkü bina konumları ring saatlerinin aksine değişmiyor. Aynı gerekçe ring **durakları** için de kabul edildi — bkz. [[wiki/decisions/008-durak-topolojisi-asset]]. Ölçüt "kim giriyor" değil, **ne sıklıkla değişiyor**.

## Tasarımın bedeli

Elle girilen veri **doğrulanmıyor**. Şema garantisi yok, tip kontrolü yok, referans bütünlüğü yok. Üretimde bunun üç somut sonucu var:

1. Duraklar yanlış düğüme ve yer tutucu adlarla girilmiş → durak arayüzü aylarca tamamen boş kaldı. **Çözüldü:** duraklar elle girişten çıkarılıp asset'e taşındı, bkz. [[wiki/decisions/008-durak-topolojisi-asset]]. Bu, kavramın bedelinin gerçek olduğunu gösteren en pahalı örnek.
2. Hat anahtarları iki farklı biçimde girilmiş (`au102_gidis` / `au_103_gidis`) → kodda temizleme mantığı yazılmak zorunda kalınmış. Bkz. [[wiki/data/ring-schedule]].
3. `cafeteria_menu` dökümde hiç yok, ama kod okuyor.

Yani bu kavramın maliyeti soyut değil — bugün üretimde çalışmayan bir arayüz olarak duruyor.

`firebase/README.md` bu riski görmüş: içe aktarma yönergesinde "kök düğümde içe aktarırsan tüm veritabanını silersin" uyarısı var.

## İlgili sayfalar

[[wiki/decisions/002-realtime-db-firestore-ayrimi]] · [[wiki/data/ring-stops]] · [[wiki/data/ring-schedule]] · [[wiki/data/cafeteria-menu]] · [[wiki/features/ring]]
