---
title: Dizin
type: index
updated: 2026-07-28
status: current
---

# Dizin

Wiki'nin içerik kataloğu. Bir soruya cevap ararken önce buraya bak, sonra ilgili sayfaya in.

Başlangıç noktası: [[wiki/overview]] — projenin sentezi ve bugünkü durumu.

## Feature'lar

| Sayfa | Özet |
| --- | --- |
| [[wiki/features/auth]] | Kayıt, giriş, e-posta doğrulama. Domain kısıtının uygulandığı yer. |
| [[wiki/features/home]] | Hem sekme kabuğu hem ana sayfa içeriği. Hızlı erişim kartları henüz bağlı değil. |
| [[wiki/features/cafeteria]] | Menü, puanlama, yorum ve yorum oylaması. İki veritabanına birden dokunan tek feature. |
| [[wiki/features/ring]] | Ring saatleri ve duraklar. 18 bileşen; durak verisi eksik olduğu için bir kısmı bugün görünmüyor. |
| [[wiki/features/community]] | Kulüpler, kulüp etkinlikleri, takip et/bırak. |
| [[wiki/features/student_events]] | Öğrencilerin kendi etkinlikleri. Yetki yazarlığa bağlı. |
| [[wiki/features/board]] | İlan panosu. Güvenlik kuralı yok — en kritik açık. |
| [[wiki/features/profile]] | Kullanıcı kesiti. Beş veri yoluna dokunuyor; hiçbir dökümanda geçmiyor. |
| [[wiki/features/map]] | Statik marker'lı kampüs haritası. Firebase'e dokunmayan tek feature. |

## Veri yolları

### Firestore

| Sayfa | Özet |
| --- | --- |
| [[wiki/data/users]] | Kullanıcı profili. Üç feature yazıyor. |
| [[wiki/data/clubs]] | Kulüpler. Yalnızca `followerCount` güncellenebilir. |
| [[wiki/data/club-events]] | Kulüp etkinlikleri, `clubs` altında alt koleksiyon. Uygulamada yazan yok. |
| [[wiki/data/student-events]] | Öğrenci etkinlikleri. Üç feature'ın paylaştığı koleksiyon. |
| [[wiki/data/announcements]] | Duyurular. Salt okunur, Console'dan girilir. |
| [[wiki/data/cafeteria-ratings]] | Yemek puanları ve yorumlar. `avgRating` sunucuda korunmasız. |
| [[wiki/data/board]] | İlan panosu. **Güvenlik kuralı yok.** |
| [[wiki/data/feedback]] | Geri bildirim. Tek yönlü kutu — yazan bile okuyamaz. |

### Realtime Database

| Sayfa | Özet |
| --- | --- |
| [[wiki/data/ring-schedule]] | Hat kalkış saatleri. Dört hat, anahtar biçimi iki türlü. |
| [[wiki/data/ring-stops]] | Durak havuzu. **Üretimde yanlış düğümde — bugün boş.** |
| [[wiki/data/cafeteria-menu]] | Günlük menü. Üretim dökümünde yok. |

## Kavramlar

| Sayfa | Özet |
| --- | --- |
| [[wiki/concepts/katman-disiplini]] | `Model → Service → Provider → Page` kuralının kodda ne kadar tutulduğu. |
| [[wiki/concepts/ogrenci-dogrulama]] | Üç katmanlı öğrenci kontrolü ve `email_verified` boşluğu. |
| [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]] | Backend olmadığı için tüm yetkinin kurallarda yaşaması. Üç olgunluk seviyesi. |
| [[wiki/concepts/elle-girilen-veri]] | Üniversitenin Console'dan girdiği veri, getirisi ve bugünkü bedeli. |
| [[wiki/concepts/denormalizasyon]] | Dört kopyalama noktası ve bayatlama riskleri. |

## Kararlar

| Sayfa | Özet |
| --- | --- |
| [[wiki/decisions/001-clean-architecture-reddi]] | Neden UseCase/Repository yok, karşılığında ne ödendi. |
| [[wiki/decisions/002-realtime-db-firestore-ayrimi]] | Hangi veri nereye, neden. |
| [[wiki/decisions/003-eposta-domain-kisiti]] | `@ogr.akdeniz.edu.tr` kısıtı ve Google Sign-In reddi. |
| [[wiki/decisions/004-rating-transaction]] | Cloud Function yerine client transaction'ı. |
| [[wiki/decisions/005-shell-route-navigasyon]] | Beş sekme, dört gizli feature. |
| [[wiki/decisions/006-durak-bazli-saat-yok]] | Tahmin üretmeme ilkesi. |
| [[wiki/decisions/007-kulup-etkinligi-adminuid]] | Kulüp yetkisi vs yazar yetkisi. Kural bugün ölü. |

## Kaynaklar

| Sayfa | Özet |
| --- | --- |
| [[wiki/sources/development-md]] | Otoriter mimari dökümanı. Wiki onu kopyalamaz, link verir. |
| [[wiki/sources/agent-dokumanlari]] | `CLAUDE.md` + `AGENTS.md` — sıkıştırılmış agent yönergesi. |
| [[wiki/sources/firestore-rules]] | Yetkilendirmenin sunucu tarafı gerçeği. |
| [[wiki/sources/realtime-db-json]] | Üretim RTDB dökümü. Dökümanla üç noktada çelişiyor. |
| [[wiki/sources/kod-tabani]] | 2026-07-28 kod taraması, HEAD `e36ca3d`. |

## Ayrıca

- [[wiki/log]] — kronolojik etkinlik kaydı
- `../CLAUDE.md` — wiki şeması, bakım kuralları
- `../raw/README.md` — kaynak nasıl eklenir
