---
title: profile
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/agent-dokumanlari]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/profile/services/profile_service.dart
    sha: 0c42d94
---

# profile

## Sorumluluk

Kullanıcının kendi kesitini toplamak: bilgileri, takip ettiği kulüpler, oluşturduğu etkinlikler, puanladığı yemekler. Ayrıca şifre değiştirme, çıkış ve geri bildirim gönderme.

**Projedeki tek "toplayıcı" feature** — kendi koleksiyonu yok, başka feature'ların verisini kullanıcı ekseninde birleştiriyor.

## Belgelenmemiş feature

> **Çelişki (2026-07-28):** Bu feature `DEVELOPMENT.md`, `CLAUDE.md` ve `AGENTS.md`'nin hiçbirinde geçmiyor. Üçü de feature listesini sekiz olarak veriyor: `auth, board, cafeteria, community, home, map, ring, student_events`. Kodda dokuz var. `profile` son eklenen feature (commit `0c42d94`, "profile edits") ve döküman güncellemesi atlanmış.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| [[wiki/data/users]] | okur (dolaylı, `shared/providers/user_provider.dart`) |
| [[wiki/data/clubs]] | okur (takip edilenler) |
| [[wiki/data/student-events]] | okur (`authorUid` = kullanıcı) |
| [[wiki/data/cafeteria-ratings]] | okur (`ratings/{uid}` alt dokümanları) |
| [[wiki/data/feedback]] | yazar |

**Beş veri yoluna dokunan tek feature.** Şema değişikliklerine en kırılgan yer burası.

## Komşu feature'lar

[[wiki/features/community]], [[wiki/features/student_events]], [[wiki/features/cafeteria]], [[wiki/features/auth]] — hepsinin verisini okuyor ama hiçbirinin servisini import etmiyor. Cross-feature import yasağına uyum, koleksiyonlara doğrudan gitmekle sağlanmış.

## Kararlar

- **Kendi modelleri var.** `ProfileClubSummary`, `ProfileEventSummary`, `ProfileRatedMeal` — başka feature'ların modellerini kullanmak yerine hafif özetler. Cross-feature import yasağının doğal sonucu, ama aynı veri üç ayrı modelle temsil ediliyor.
- **Puanlanan yemekler `users.ratedMealIds` üzerinden.** Collection-group sorgusu yerine kullanıcı dokümanındaki indeks kullanılıyor. Bkz. [[wiki/data/users]].
- **Geri bildirim tek yönlü.** Gönderilir, hiç okunmaz — kullanıcı kendi gönderdiğini bile göremez. Bkz. [[wiki/data/feedback]].
- **Sekme değil.** `/home/profile` altında. Bkz. [[wiki/decisions/005-shell-route-navigasyon]].

## Açık sorular

- Aynı veri için üç ayrı özet modeli, cross-feature import yasağının maliyeti. `shared/models/` gibi bir katman düşünüldü mü?
- Feature dökümanlara eklenmeli — bu wiki'nin ilk somut aksiyon önerisi.
- Profil fotoğrafı yok; `shared/services/storage_service.dart` var ama profil bunu kullanmıyor.
