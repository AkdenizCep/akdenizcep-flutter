---
title: Kod tabanı taraması
type: source
updated: 2026-07-28
status: current
sources: []
code_refs:
  - path: lib/app/router.dart
    sha: 089b8e8
  - path: lib/features/auth/services/auth_service.dart
    sha: 089b8e8
  - path: lib/features/board/services/board_service.dart
    sha: ae378bb
  - path: lib/features/cafeteria/services/cafeteria_service.dart
    sha: 089b8e8
  - path: lib/features/community/services/community_service.dart
    sha: 0c42d94
  - path: lib/features/home/services/home_service.dart
    sha: 44ab794
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
  - path: lib/features/ring/services/ring_service.dart
    sha: a32558f
  - path: lib/features/student_events/services/student_events_service.dart
    sha: 0c42d94
  - path: lib/shared/providers/user_provider.dart
    sha: 089b8e8
---

# Kaynak — Kod tabanı taraması

## Künye

- **Kapsam:** `lib/features/*/services/`, `lib/shared/`, `lib/app/router.dart`
- **Tarama anı:** 2026-07-28, HEAD `e36ca3d`
- **Yöntem:** Servis katmanındaki tüm Firebase erişimleri (`collection(`, `doc(`, `.ref(`, `FirebaseDatabase`, `FirebaseStorage`) tarandı; her veri yolu okuyan/yazan feature'a bağlandı.

> **Not:** Tarama anında çalışma ağacında commit edilmemiş değişiklikler vardı (`ring/` altındaki dosyalar, `DEVELOPMENT.md`, `router.dart`). `code_refs` SHA'ları o dosyaların son commit'ini gösterir, çalışma ağacındaki hâlini değil.

## Özet

Servis katmanı, `DEVELOPMENT.md`'nin koyduğu kurala **tam uyuyor**: Firebase erişimi yalnızca `services/` altında ve bir istisna var — `lib/shared/providers/user_provider.dart:24` doğrudan `users` koleksiyonuna gidiyor. Bkz. [[wiki/concepts/katman-disiplini]].

Servis envanteri:

| Servis | Backend | Yol |
| --- | --- | --- |
| `auth_service.dart` | Auth + Firestore | `users/{uid}` yazar |
| `board_service.dart` | Firestore | `board` |
| `cafeteria_service.dart` | Firestore + RTDB | `cafeteria_ratings`, `users`, `cafeteria_menu` |
| `community_service.dart` | Firestore | `clubs`, `clubs/{id}/club-events`, `users` |
| `home_service.dart` | Firestore | `announcements`, `student-events` |
| `profile_service.dart` | Firestore | `clubs`, `student-events`, `cafeteria_ratings/*/ratings`, `feedback` |
| `ring_service.dart` | RTDB | `ring_schedule`, `ring_stops` |
| `student_events_service.dart` | Firestore | `student-events` |
| `shared/storage_service.dart` | Storage | serbest yol |
| `shared/location_service.dart` | — | cihaz konumu, Firebase yok |

## Öne çıkan bulgular

- **Dokuz feature var, döküman sekiz sayıyor.** `profile` hiçbir dökümanda geçmiyor. Bkz. [[wiki/features/profile]].
- **`board` koleksiyonunun security rule'u yok.** Bkz. [[wiki/data/board]].
- **`feedback` koleksiyonu yalnızca kuralda ve `profile_service.dart`'ta var**, dökümanda yok. Bkz. [[wiki/data/feedback]].
- **Yetkilendirme iki yerde.** `board_service.dart` silme yetkisini client'ta kontrol ediyor (`doc.data()?['authorUid'] != authorUid`), sunucuda karşılığı yok. Bkz. [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]].
- **Navigasyon `StatefulShellRoute.indexedStack`** ile beş sekmeli. `board` ve `profile` sekme değil, `/home` altında alt rota. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].
- **`map` feature'ının yalnızca `pages/` klasörü var** — model, servis, provider yok. Statik marker'lı Google Maps.

## Bu kaynaktan türeyen sayfalar

Tüm [[wiki/index|features]] ve [[wiki/index|data]] sayfaları · [[wiki/concepts/katman-disiplini]] · [[wiki/concepts/denormalizasyon]] · [[wiki/decisions/005-shell-route-navigasyon]]
