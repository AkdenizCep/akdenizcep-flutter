# Sade profil ve ayarlar uygulama planı

Onaylanan tasarım: Figma GD0OHNDhsfDE1dXRvq5bl6, profil 3:2 ve ayarlar 7:2.

Amaç: Kişisel profil; fotoğraf, QR, dört topluluk, iki katılınan ve iki oluşturulan etkinlik önizlemesi. Hesap bilgileri, tema, şifre sıfırlama, geri bildirim ve çıkış ayrı Ayarlar ekranında. Profil kök navigator üzerinde; alt gezinme yok.

Mimari: Model → Service → Provider → Page. Mevcut ortak etkinlik akışı katılım bilgisinin kaynağı; attendeeIds üyeliği esas alınır, QR yoklaması değildir. Örnek Figma içeriği yerine gerçek kullanıcı verileri kullanılır. Mevcut Flutter tema ve avatar bileşenleri korunur.

- [x] Profil başlığı ve veri önizlemeleri: mevcut fotoğraf testini genişlet, başarısızlığı doğrula; profile_info_card, profil bölümleri ve profile_provider dosyalarını güncelle. Katılım filtreleme, farklı etkinlik kaynakları, boş/hata durumlarını test et.
- [x] Tam listeler: profil altında clubs, joined-events, created-events rotalarını ekle. Önizleme sınırını ve tüm listeye/detaya navigasyonu widget testleriyle doğrula.
- [x] Ayarlar: settings ve settings/account rotaları; mevcut tema tercihi, şifre sıfırlama, feedback ve çıkış işlevleri. İşlem durumu provider'da, Firebase çağrıları serviste. Yinelenen gönderimi engelle, hataları görünür tut, çıkış onayını koru.
- [x] flutter analyze ve flutter test çalıştır. Dar ekran/büyük yazı ve açık/koyu tema widget kontrolleri; profil ve ayarlar renderlarını incele. Canlı Firebase doğrulamasının sınırını açıkça raporla.

