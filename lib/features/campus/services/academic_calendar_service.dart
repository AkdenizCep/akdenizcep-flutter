import '../models/academic_calendar.dart';

/// Akademik takvim + resmî tatil verisinin tek kaynağı.
///
/// Firebase kullanmaz — üniversitenin akademik takvimi yılda bir kez
/// yayınlanır ve uygulama sürümüyle birlikte gelir (bkz. ring durak
/// topolojisinin asset'e taşınma kararıyla aynı gerekçe: nadiren değişen,
/// üniversite kaynaklı veri).
class AcademicCalendarService {
  /// "Yarıyıllık Eğitim Öğretim Veren Birimler" tablosu. Tıp Fakültesi,
  /// Diş Hekimliği Fakültesi ve Hukuk Fakültesi kendi yıllık takvimlerine
  /// sahiptir ve burada yer almaz.
  List<AcademicMilestone> get milestones => _milestones;

  List<PublicHoliday> get holidays => _holidays;

  /// Bugün hâlâ geçerli olan ya da gelecekteki tüm akademik dönüm
  /// noktalarını ve resmî tatilleri tek bir zaman çizelgesinde birleştirir.
  ///
  /// Aralıklı bir süreç (ör. "7-11 Eylül") başlangıcı geçse bile bitişine
  /// kadar listede kalır — yoksa süreç ortasında "sıradaki önemli tarih"
  /// kartı yanlışlıkla bir sonraki, daha az acil olaya atlardı. Sıralama:
  /// önce hâlâ devam edenler (en erken bitecek en başta), sonra henüz
  /// başlamamışlar (en erken başlayacak en başta).
  List<AcademicEvent> upcomingEvents(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    final events = <AcademicEvent>[
      for (final m in _milestones) ...[
        if (m.fall != null)
          AcademicEvent(date: m.fall!.start, end: m.fall!.end, title: m.title),
        if (m.spring != null)
          AcademicEvent(
            date: m.spring!.start,
            end: m.spring!.end,
            title: m.title,
          ),
      ],
      for (final h in _holidays)
        AcademicEvent(date: h.date, title: h.title, isHoliday: true),
    ]..retainWhere((e) => !(e.end ?? e.date).isBefore(today));

    events.sort((a, b) {
      final aOngoing = a.isOngoingOn(today);
      final bOngoing = b.isOngoingOn(today);
      if (aOngoing != bOngoing) return aOngoing ? -1 : 1;
      if (aOngoing) return (a.end ?? a.date).compareTo(b.end ?? b.date);
      return a.date.compareTo(b.date);
    });
    return events;
  }

  /// Verilen ana bakılırsa hangi yarıyılın gösterilmesi mantıklı — Bahar
  /// dönemi başlamadan önce Güz, başladıktan sonra Bahar.
  AcademicTerm currentTerm(DateTime now) {
    final springStart = _milestones
        .firstWhere((m) => m.title == 'Derslerin Başlaması')
        .spring!
        .start;
    return now.isBefore(springStart) ? AcademicTerm.fall : AcademicTerm.spring;
  }

  static final List<AcademicMilestone> _milestones = [
    AcademicMilestone(
      title: 'Ders Görevlendirmelerinin Rektörlüğe Bildirilmesinin Son Günü',
      fall: AcademicDateRange(DateTime(2026, 8, 14)),
      spring: AcademicDateRange(DateTime(2026, 12, 31)),
    ),
    AcademicMilestone(
      title: 'Özel Öğrenci Başvurusu (Gelen ve Giden) İçin Son Gün',
      fall: AcademicDateRange(DateTime(2026, 8, 21)),
      spring: AcademicDateRange(DateTime(2027, 1, 15)),
    ),
    AcademicMilestone(
      title: 'Katkı Payı / Öğrenim Ücretleri Yatırma ve Kayıt Yenileme Süresi',
      fall: AcademicDateRange(
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 11),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 1, 25),
        DateTime(2027, 1, 29),
      ),
    ),
    AcademicMilestone(
      title: 'Danışman Onayı',
      fall: AcademicDateRange(
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 13),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 1, 25),
        DateTime(2027, 1, 31),
      ),
    ),
    AcademicMilestone(
      title: 'Öğrenime Ara İzni Başvurusu İçin Son Gün',
      fall: AcademicDateRange(DateTime(2026, 9, 11)),
      spring: AcademicDateRange(DateTime(2027, 1, 29)),
    ),
    AcademicMilestone(
      title: 'Derslerin Başlaması',
      fall: AcademicDateRange(DateTime(2026, 9, 14)),
      spring: AcademicDateRange(DateTime(2027, 2, 1)),
    ),
    AcademicMilestone(
      title: 'Sosyal Transkript Etkinlik Başvuru Tarihleri',
      fall: AcademicDateRange(
        DateTime(2026, 9, 14),
        DateTime(2026, 12, 20),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 2, 1),
        DateTime(2027, 5, 14),
      ),
    ),
    AcademicMilestone(
      title:
          'Kapatılacak veya Şubelere Ayrılan Derslerin Rektörlüğe '
          'Bildirilmesinin Son Günü',
      fall: AcademicDateRange(DateTime(2026, 9, 14)),
      spring: AcademicDateRange(DateTime(2027, 2, 1)),
      hasFootnote: true,
    ),
    AcademicMilestone(
      title:
          'Ders Bırakma ve Ders Ekleme Süresi (Ekle-Çıkar) / '
          'Mazeretli Ders Kaydı',
      fall: AcademicDateRange(
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 18),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 2, 2),
        DateTime(2027, 2, 5),
      ),
    ),
    AcademicMilestone(
      title: 'Ders Bırakma ve Ders Ekleme (Ekle-Çıkar) Danışman Onayı',
      fall: AcademicDateRange(
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 20),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 2, 2),
        DateTime(2027, 2, 7),
      ),
    ),
    AcademicMilestone(
      title: 'Dersten Çekilmenin Son Günü',
      fall: AcademicDateRange(DateTime(2026, 10, 2)),
      spring: AcademicDateRange(DateTime(2027, 2, 19)),
    ),
    AcademicMilestone(
      title:
          'Ara Sınav Sonuçlarının ve Diğer Yıl/Yarıyıl İçi Ölçme Araçları '
          'Sonuçlarının Otomasyon Sistemine Girilmesinin Son Tarihi',
      fall: AcademicDateRange(DateTime(2026, 12, 20)),
      spring: AcademicDateRange(DateTime(2027, 5, 14)),
    ),
    AcademicMilestone(
      title: 'Derslerin Sona Ermesi',
      fall: AcademicDateRange(DateTime(2026, 12, 20)),
      spring: AcademicDateRange(DateTime(2027, 5, 14)),
    ),
    AcademicMilestone(
      title: 'Yarıyıl Sonu Sınavları',
      fall: AcademicDateRange(
        DateTime(2026, 12, 21),
        DateTime(2026, 12, 31),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 5, 24),
        DateTime(2027, 6, 4),
      ),
    ),
    AcademicMilestone(
      title:
          'Yarıyıl Sonu Sınav Sonuçlarının Otomasyon Sistemine Girilmesinin '
          'Son Günü',
      fall: AcademicDateRange(DateTime(2027, 1, 4)),
      spring: AcademicDateRange(DateTime(2027, 6, 7)),
    ),
    AcademicMilestone(
      title: 'Yıl/Yarıyıl Sonu İkinci Sınavı (Bütünleme) Başvuru Tarihleri',
      fall: AcademicDateRange(
        DateTime(2027, 1, 2),
        DateTime(2027, 1, 9),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 6, 5),
        DateTime(2027, 6, 12),
      ),
    ),
    AcademicMilestone(
      title: 'Yıl/Yarıyıl Sonu İkinci Sınavı (Bütünleme) Tarihleri',
      fall: AcademicDateRange(
        DateTime(2027, 1, 11),
        DateTime(2027, 1, 15),
      ),
      spring: AcademicDateRange(
        DateTime(2027, 6, 14),
        DateTime(2027, 6, 18),
      ),
    ),
    AcademicMilestone(
      title:
          'Yıl/Yarıyıl Sonu İkinci Sınavı (Bütünleme) Sonuçlarının '
          'Otomasyon Sistemine Girilmesinin Son Günü',
      fall: AcademicDateRange(DateTime(2027, 1, 18)),
      spring: AcademicDateRange(DateTime(2027, 6, 21)),
    ),
  ];

  /// 19 Mayıs 2027 hem millî bayram hem Kurban Bayramı'nın 4. gününe denk
  /// geliyor — kaynak tabloda iki ayrı satır, burada tek gün olduğu için
  /// tek satırda birleştirildi.
  static final List<PublicHoliday> _holidays = [
    PublicHoliday(
      date: DateTime(2026, 10, 28),
      title: 'Cumhuriyet Bayramı',
      halfDay: true,
    ),
    PublicHoliday(date: DateTime(2026, 10, 29), title: 'Cumhuriyet Bayramı'),
    PublicHoliday(date: DateTime(2027, 1, 1), title: 'Yılbaşı'),
    PublicHoliday(
      date: DateTime(2027, 3, 8),
      title: 'Ramazan Bayramı Arefesi',
      halfDay: true,
    ),
    PublicHoliday(
      date: DateTime(2027, 3, 9),
      title: 'Ramazan Bayramı (1. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 3, 10),
      title: 'Ramazan Bayramı (2. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 3, 11),
      title: 'Ramazan Bayramı (3. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 4, 23),
      title: 'Ulusal Egemenlik ve Çocuk Bayramı',
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 1),
      title: 'Emek ve Dayanışma Günü',
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 15),
      title: 'Kurban Bayramı Arefesi',
      halfDay: true,
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 16),
      title: 'Kurban Bayramı (1. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 17),
      title: 'Kurban Bayramı (2. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 18),
      title: 'Kurban Bayramı (3. gün)',
    ),
    PublicHoliday(
      date: DateTime(2027, 5, 19),
      title:
          "Atatürk'ü Anma, Gençlik ve Spor Bayramı · Kurban Bayramı (4. gün)",
    ),
    PublicHoliday(
      date: DateTime(2027, 7, 15),
      title: 'Demokrasi ve Millî Birlik Günü',
    ),
    PublicHoliday(date: DateTime(2027, 8, 30), title: 'Zafer Bayramı'),
  ];
}
