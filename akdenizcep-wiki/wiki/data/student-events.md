---
title: student-events
type: data
updated: 2026-10-03
status: stale
sources:
  - "[[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]]"
---

# student-events

> **Kaldırıldı (2026-10-03).** Koleksiyon artık kullanılmıyor. Karar: [[wiki/decisions/009-ogrenci-etkinliklerinin-kaldirilmasi]]. Etkinlikler artık yalnızca [[wiki/data/club-events]].

## Yol

Firestore · `student-events/{seventId}` (alt koleksiyon: `comments`)

## Durum

- `firestore.rules`'ta eşleşen kural yok: koleksiyona okuma/yazma, admin dahil, reddedilir.
- Uygulama, admin paneli ve scriptler koleksiyonu artık okumuyor/yazmıyor.
- Mevcut dokümanlar **yedeksiz silinecek** (kullanıcı kararı). Silme bu sayfa yazılırken yapılmamıştı; yapılınca bu satır güncellenmeli. Doğrulama: `functions` altında `npm run schema:inventory` artık bu koleksiyonu saymıyor, bu yüzden Firebase Console'dan bakılmalı.

## Eski şema (silinen veriyi tanımak için)

`title`, `authorUid`, `authorName`, `date`, `location`, `locationLatitude`, `locationLongitude`, `description`, `category`, `imageUrl`, `capacity`, `attendeeIds`, `attendeeCount`, `moderationStatus`, `moderatedAt`, `moderatedBy`, `createdAt`.

Bu sayfa, eski sayfalardan gelen `[[wiki/data/student-events]]` linkleri kırılmasın diye duruyor.
