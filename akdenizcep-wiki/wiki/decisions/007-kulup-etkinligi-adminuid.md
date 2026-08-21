---
title: 007 — Kulüp etkinliği yetkisi adminUid'e bağlı
type: decision
updated: 2026-08-21
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: firestore.rules
    sha: 5a84d8d
  - path: lib/shared/services/event_feed_service.dart
    sha: 5a84d8d
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
- Alt koleksiyon seçimi "tüm kulüplerin yaklaşan etkinlikleri" sorgusunu pahalılaştırıyor. [[wiki/features/home]] bu yüzden ana sayfada yalnızca öğrenci etkinliklerini gösteriyor.

## Güncelleme (2026-08-21) — tek yöneticiden yönetici üyelere

Karar anında "kulüp başına tek yönetici" kısıtı bilinçliydi; bu artık geçerli değil. `clubs/{id}.adminUids` (string dizisi) eklendi — başkan (`adminUid`), kendi topluluğuna öğrenci numarasıyla **yönetici üyeler** ekleyebiliyor (bkz. [[wiki/data/clubs]], [[wiki/features/community]]). Yönetici üyeler başkanla tam aynı yetkiye sahip: `club-events` yazma ve kulüp profili düzenleme. Üye ekleme/çıkarma yetkisi yalnızca başkanda kalıyor.

`isClubAdmin(clubId)` fonksiyonu genişletildi: `isClubPresident(clubId) || uid in adminUids`. `event_feed_service.dart:getAdminClubs` da `Filter.or(adminUid==uid, adminUids arrayContains uid)` ile aynı ayrımı yapıyor — "kimin adına" seçicisi artık yönetici üyelerin de kulübünü listeliyor.

`adminUids` alanı olmayan eski kulüp dokümanları kırılmıyor: hem kural hem model "alan yoksa boş dizi" davranıyor.

## Kural bugün canlı

> Bu maddenin önceki hâli ("uygulamada kulüp etkinliği oluşturan hiçbir arayüz yok, kural ölü") artık **yanlış**: `lib/features/student_events/pages/create_event_page.dart`, kullanıcı bir kulübün başkanıysa/yönetici üyesiyse "kimin adına" seçiciyle kulüp etkinliği oluşturmayı destekliyor. Çelişki bu güncellemeyle çözüldü, ayrı bir sayfa gerekmedi.

## Kaynak

`firestore.rules` → `isClubPresident`, `clubAdminUids`, `isClubAdmin`, `match /clubs/{clubId}`; `DEVELOPMENT.md` → "Önemli Notlar"; `lib/shared/services/event_feed_service.dart:getAdminClubs`.
