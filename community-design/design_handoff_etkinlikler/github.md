repo: AkdenizCep/akdenizcep-flutter
branch: main
path: lib/

## Last sync
date: 2026-08-08T23:20:13Z

### Updated in this project
- Etkinlik akışı için 3 farklı geçiş modeli tasarlandı (kaynak sekmeleri / kulüp şeridi / kategori + gün şeridi)
- Etkinlik detay sayfası yeniden tasarlandı: katıl, kulüp kartı, konum, yorumlar
- Kulüp profili ve etkinlik oluşturma ekranları eklendi
- Renk, tipografi ve alt navigasyon barı lib/app/theme.dart + home_page.dart'tan birebir alındı

## Screen map
| Proje ekranı | Kaynak dosyalar |
| --- | --- |
| Etkinlikler.dc.html · 1a akış | lib/features/student_events/pages/student_events_page.dart, .../components/student_event_card.dart |
| Etkinlikler.dc.html · 1b akış | .../student_event_card.dart, lib/features/community/pages/community_page.dart |
| Etkinlikler.dc.html · 1c akış | .../student_events_page.dart, lib/features/community/models/club_event.dart |
| Etkinlikler.dc.html · 1d detay | lib/features/student_events/pages/student_event_detail_page.dart, lib/features/community/pages/event_detail_page.dart |
| Etkinlikler.dc.html · 1e kulüp profili | lib/features/community/pages/club_detail_page.dart, .../models/club.dart |
| Etkinlikler.dc.html · 1f oluşturma | lib/features/student_events/pages/create_event_page.dart |
| Alt navigasyon barı (tüm ekranlar) | lib/features/home/pages/home_page.dart |
| Renk / tipografi | lib/app/theme.dart |
| Rotalar | lib/app/router.dart |
