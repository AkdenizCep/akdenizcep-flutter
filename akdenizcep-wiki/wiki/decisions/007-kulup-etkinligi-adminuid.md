---
title: 007 — Kulüp etkinliği yetkisi adminUid'e bağlı
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: firestore.rules
    sha: 0c42d94
---

# 007 — Kulüp etkinliği yetkisi adminUid'e bağlı

## Bağlam

Uygulamada iki tür etkinlik var: kulüplerin düzenlediği ([[wiki/data/club-events]]) ve öğrencilerin kendi başına açtığı ([[wiki/data/student-events]]). İkisinin yetkilendirme modeli farklı olmalı — kulüp adına etkinlik açmak herkese açık olamaz.

## Karar

İki ayrı model:

| | Kim yazabilir | Kural |
| --- | --- | --- |
| `club-events` | Yalnızca kulüp yöneticisi | `request.auth.uid == get(clubs/$(clubId)).data.adminUid` |
| `student-events` | Her öğrenci, kendi adına | `request.auth.uid == request.resource.data.authorUid` |

Kulüp etkinliği kuralı, üst dokümandan `get()` çağrısıyla `adminUid` okuyup karşılaştırıyor. Etkinliğin kulübün **alt koleksiyonunda** durması bu `get()`'i mümkün kılan şey.

## Gerekçe

Kulüp kimliği kurumsal: bir kulüp adına duyurulan etkinlik o kulübü bağlar. Yetki bu yüzden içeriğin yazarına değil, kulübün yöneticisine bağlanmış.

Öğrenci etkinliğinde böyle bir kurumsal kimlik yok — sorumluluk doğrudan yazarda, dolayısıyla `authorUid` yeterli.

`adminUid`'in `clubs` dokümanında tutulması ve `clubs`'ın `create`/`delete` izinlerinin herkese kapalı olması ([[wiki/data/clubs]]) zinciri tamamlıyor: kulüp yöneticiliği yalnızca Console'dan atanabilir, uygulamadan kimse kendini yönetici yapamaz.

## Sonuçları

**Kazanılan:** Temiz ve sunucuda zorlanan bir yetki modeli. Kulüp yöneticiliği devri tek alan güncellemesiyle yapılıyor.

**Ödenen:**

- Kural her yazmada bir ek doküman okuması yapıyor (`get()` çağrısı Firestore'da ücretlendirilir)
- Kulüp başına **tek** yönetici. Yönetim kurulu modeli yok; `adminUid` dizi değil string.
- Alt koleksiyon seçimi "tüm kulüplerin yaklaşan etkinlikleri" sorgusunu pahalılaştırıyor. [[wiki/features/home]] bu yüzden ana sayfada yalnızca öğrenci etkinliklerini gösteriyor.

## Kural bugün ölü

> **Çelişki (2026-07-28):** Uygulamada kulüp etkinliği oluşturan **hiçbir arayüz yok**. `community_service.dart` yalnızca okuma yapıyor. Yani `adminUid` kuralı yazılmış ama hiç kullanılmıyor; kulüp etkinlikleri bugün Console'dan giriliyor.
>
> Kural ileriye dönük yazılmış olabilir (yönetici arayüzü planlanıyor), ya da plan değişmiş ve kural kalmış olabilir. Kaynak yok — bu soru kullanıcıya sorulmalı.

## Kaynak

`firestore.rules:43-48` ve `55-61`; `DEVELOPMENT.md` → "Önemli Notlar".
