---
title: home
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/home/services/home_service.dart
    sha: 44ab794
  - path: lib/app/router.dart
    sha: 089b8e8
---

# home

## Sorumluluk

İki iş birden yapıyor ve bu ayrım önemli:

1. **Kabuk (`HomePage`).** `StatefulShellRoute` gövdesi — beş sekmeli alt navigasyonu barındırır. Diğer tüm feature'lar bunun içinde yaşar.
2. **İçerik (`HomeContentPage`).** Duyuru slider'ı ve yaklaşan etkinlik kartları.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/announcements]] | okur (`createdAt` azalan) |
| [[wiki/data/student-events]] | okur (`date >= şimdi`, ilk 10) |

Yazma yok.

## Komşu feature'lar

Kabuk olduğu için **hepsiyle** komşu. `/home` altında üç alt rota barındırıyor: `community`, `board`, `profile` — bunlar sekme değil.

Veri düzeyinde: [[wiki/features/student_events]] ile aynı koleksiyonu okuyor, kendi `HomeEvent` modeliyle.

## Kararlar

- **Kabuk ile içeriğin ayrılması.** `HomePage` navigasyon iskeletini, `HomeContentPage` ilk sekmenin içeriğini taşıyor. Böylece "ana sayfa" hem kap hem sayfa olabiliyor. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].
- **Ana sayfada kulüp etkinliği yok.** Yalnızca öğrenci etkinlikleri gösteriliyor. Muhtemel sebep: `club-events` alt koleksiyonda ve tümünü çekmek collection-group indeksi ister. Bkz. [[wiki/data/club-events]].
- **`limit(10)`.** Ana sayfadaki tek limitli sorgu bu — [[wiki/data/announcements]] limitsiz.

## Hızlı erişim kartları çalışmıyor

> **Çelişki (2026-07-28):** `DEVELOPMENT.md` ve `CLAUDE.md` "OBS sayfası `WebView` ile açılır — native entegrasyon yoktur" diyor. Kodda WebView **yok**: `pubspec.yaml` içinde `webview_flutter` veya `url_launcher` bağımlılığı bulunmuyor, ve ana sayfadaki OBS kartının `onTap` gövdesi boş (`home_page.dart:424`).
>
> Aynı durum diğer üç hızlı erişim kartında da geçerli: **TL Yükleme**, **Akademik Takvim**, **Acil Durum** — dördü de `onTap: () {}`. Yani ana sayfadaki hızlı erişim ızgarası bütünüyle görsel bir yer tutucu.
>
> Döküman planlanan davranışı yazmış, kod henüz oraya gelmemiş. Bu bir hata değil eksik iş — ama dökümanı okuyan biri OBS'nin çalıştığını sanır.

## Açık sorular

- Kulüp etkinliklerinin ana sayfada olmaması bilinçli bir ürün kararı mı, teknik kaçınma mı? Kaynak yok.
- Hızlı erişim kartları hangi sırayla bağlanacak? OBS için WebView mi, tarayıcıya yönlendirme mi?
- Duyuru sorgusunda limit olmaması gözden kaçmış olabilir; duyuru sayısı arttıkça ana sayfa açılışı yavaşlar.
- `board` ve `profile` sekme yerine `/home` altında olması gezinmede keşfedilebilirliği düşürüyor olabilir — kullanıcı verisi yok.
