---
title: Genel bakış
type: overview
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/agent-dokumanlari]]"
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/realtime-db-json]]"
  - "[[wiki/sources/kod-tabani]]"
---

# Akdeniz Cep — Genel bakış

## Ne yapıyor

Akdeniz Üniversitesi öğrencileri için mobil uygulama. Kampüse dağılmış servisleri tek yerde topluyor: yemekhane menüsü ve puanları, ring saatleri, kulüp ve öğrenci etkinlikleri, duyurular, ilan panosu, kampüs haritası.

**Yığın:** Flutter · Firebase (Firestore, Auth, Realtime DB, Storage) · Riverpod · go_router
**Firebase projesi:** `akdeniz-cep-36d3f`

## Şekli belirleyen üç karar

Projenin bugünkü hâli büyük ölçüde üç seçimden çıkıyor:

**1. Backend yok.** Cloud Function, sunucu, API katmanı hiçbiri yok. Client doğrudan Firebase ile konuşuyor. Sonucu: tüm yetkilendirme güvenlik kurallarında yaşıyor ([[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]]), atomiklik client transaction'larıyla sağlanıyor ([[wiki/decisions/004-rating-transaction]]).

**2. Katman disiplini, soyutlama yerine.** Clean Architecture reddedilmiş ([[wiki/decisions/001-clean-architecture-reddi]]); yerine yazılı ve sıkı bir katman kuralı geçmiş ([[wiki/concepts/katman-disiplini]]). Repository arayüzü yok ama "Firebase yalnızca `services/` içinde" kuralı kodda neredeyse tam tutulmuş.

**3. İki veritabanı.** Üniversitenin elle girdiği veri RTDB'de, öğrencinin ürettiği veri Firestore'da ([[wiki/decisions/002-realtime-db-firestore-ayrimi]]). Maliyeti düşürüyor, referans bütünlüğünü feda ediyor.

## Bugünkü durum

Dokuz feature: [[wiki/features/auth]] · [[wiki/features/home]] · [[wiki/features/cafeteria]] · [[wiki/features/ring]] · [[wiki/features/community]] · [[wiki/features/student_events]] · [[wiki/features/board]] · [[wiki/features/profile]] · [[wiki/features/map]]

Beşi sekme, dördü ana sayfa altında ([[wiki/decisions/005-shell-route-navigasyon]]).

## Wiki'nin ilk taramada bulduğu beş sorun

Bunlar wiki kurulurken kod, kurallar ve dökümanlar karşılaştırılınca çıktı. Hiçbiri tek bir dosyaya bakarak görülemezdi.

**1. [[wiki/data/board]] koleksiyonunun güvenlik kuralı yok.** Firestore eşleşmeyen yolu reddeder — bu kurallar deploy edilirse ilan panosu tamamen çalışmaz. Silme yetkisi de yalnızca client'ta.

**2. [[wiki/data/ring-stops]] üretimde yanlış düğümde.** Duraklar kök düğümde (`durak_1`…), kod `ring_stops` altında arıyor. Sonuç: durak listesi, harita ve "en yakın durak" özellikleri bugün boş. [[wiki/features/ring]]'in bileşenlerinin bir kısmı hiç görünmüyor. Düzeltme adımları `firebase/README.md`'de hazır.

**3. Hızlı erişim kartları çalışmıyor.** Ana sayfadaki OBS, TL Yükleme, Akademik Takvim ve Acil Durum kartlarının `onTap` gövdeleri boş. Dökümanlar OBS'nin WebView ile açıldığını yazıyor; `pubspec.yaml`'da webview bağımlılığı yok. Bkz. [[wiki/features/home]].

**4. `avgRating` sunucuda korunmasız.** `DEVELOPMENT.md` bu alanın client'tan yazılmamasını söylüyor ama kural `allow write: if isAkdenizStudent()` veriyor. Herhangi bir öğrenci keyfi ortalama yazabilir. Bkz. [[wiki/data/cafeteria-ratings]].

**5. Kurallar sürüm kontrolü hattında değil.** `firebase.json` yalnızca FlutterFire yapılandırması içeriyor; `firestore`/`database` deploy hedefi yok. Repodaki `firestore.rules` niyeti gösteriyor, üretimdeki durumu değil. RTDB kuralları repoda hiç yok.

## Belgelerin koddan geride kaldığı yerler

- [[wiki/features/profile]] hiçbir dökümanda geçmiyor — dokuzuncu feature, üç döküman da sekiz sayıyor
- [[wiki/data/board]] ve [[wiki/data/feedback]] koleksiyonları `DEVELOPMENT.md` şemasında yok
- `users.ratedMealIds` alanı şemada yok, kod yazıyor
- `DEVELOPMENT.md`'nin RTDB örneği üretim verisiyle üç noktada uyuşmuyor ([[wiki/sources/realtime-db-json]])
- Rating için "Cloud Function" deniyor, gerçekte transaction kullanılıyor

## Sonraki adımlar için sorular

Bunlar wiki'nin cevaplayamadığı, kullanıcıdan gelmesi gereken bilgiler:

- Kulüp yöneticisi arayüzü planlanıyor mu? [[wiki/decisions/007-kulup-etkinligi-adminuid]] kuralı yazılmış ama kullanılmıyor.
- [[wiki/features/board]] ile [[wiki/features/student_events]] neden ayrı? İkisi de "öğrenci içerik üretir" akışı.
- Kullanıcı adını değiştirdiğinde eski yorumlardaki `authorName` bayat kalıyor — kabul edilmiş bir bedel mi? Bkz. [[wiki/concepts/denormalizasyon]].
- Hızlı erişim kartları hangi sırayla bağlanacak?
