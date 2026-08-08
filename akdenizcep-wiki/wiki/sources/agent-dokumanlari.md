---
title: CLAUDE.md ve AGENTS.md
type: source
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
code_refs:
  - path: CLAUDE.md
    sha: 69e0880
  - path: AGENTS.md
    sha: 5249ccd
---

# Kaynak — CLAUDE.md ve AGENTS.md

## Künye

- **Yollar:** `CLAUDE.md`, `AGENTS.md` (repo kökü)
- **Tür:** AI agent yönergesi, İngilizce
- **İlişki:** İkisi büyük ölçüde aynı içeriği taşır; `CLAUDE.md` biraz daha güncel (Cloud Function yerine transaction'dan bahsediyor, `student-events` yetki kuralını içeriyor).

## Özet

`DEVELOPMENT.md`'nin sıkıştırılmış hâli: "bir agent'ın gözden kaçırabileceği" noktalar. Kapsam:

- Komutlar: `flutter analyze`, `flutter test`, `flutter run`, `flutter pub get`. Codegen, build runner veya CI yok.
- Mimari özet ve katman disiplini — bkz. [[wiki/concepts/katman-disiplini]]
- Feature listesi
- Firebase özeti, proje kimliği `akdeniz-cep-36d3f`
- Türkçe locale, emoji yasağı, `flutter_lints` tabanı

## Bilinen sapmalar

> **Çelişki (2026-07-28):** İkisi de feature listesini `auth, board, cafeteria, community, home, map, ring, student_events` olarak veriyor — 8 feature. Kodda dokuzuncu bir feature var: `lib/features/profile/`. Bkz. [[wiki/features/profile]].

> **Çelişki (2026-07-28):** `AGENTS.md` yemek rating'i için "Cloud Function" demiyor ama `DEVELOPMENT.md`'nin Firestore şema bölümünde `avgRating` alanının yanında "Cloud Function ile güncellenir" yorumu duruyor. Kodda Cloud Function yok — güncelleme client tarafında Firestore transaction ile yapılıyor. Bkz. [[wiki/data/cafeteria-ratings]], [[wiki/decisions/004-rating-transaction]].

## Bu kaynaktan türeyen sayfalar

[[wiki/concepts/katman-disiplini]] · [[wiki/concepts/ogrenci-dogrulama]] · [[wiki/decisions/001-clean-architecture-reddi]] · [[wiki/overview]]
