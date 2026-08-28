/// Akdeniz Üniversitesi 2026-2027 Eğitim Öğretim Yılı Akademik Takvimi.
///
/// Kaynak: Üniversitenin resmi akademik takvim duyurusu. Yalnızca
/// **yarıyıllık** eğitim veren birimler için geçerli genel takvimi kapsar —
/// Tıp Fakültesi, Diş Hekimliği Fakültesi ve Hukuk Fakültesi kendi yıllık
/// takvimlerini ayrı yayınlar ve buraya dahil edilmemiştir (bkz.
/// `AcademicCalendarPage` altındaki kapsam notu).
///
/// Veri elle derlenmiştir, otomatik güncellenmez. Üniversite yeni bir
/// akademik yıl takvimi yayınladığında `AcademicCalendarService` içindeki
/// listeler elle güncellenmelidir.
library;

enum AcademicTerm { fall, spring }

extension AcademicTermLabel on AcademicTerm {
  String get label => switch (this) {
    AcademicTerm.fall => 'Güz Yarıyılı',
    AcademicTerm.spring => 'Bahar Yarıyılı',
  };
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [day] (saat/dakika yok sayılarak) [start]-[end] aralığında mı bakar.
/// [end] `null` ise yalnızca [start] ile aynı gün olup olmadığına bakılır.
bool isDateWithinRange(DateTime day, DateTime start, [DateTime? end]) {
  final target = DateTime(day.year, day.month, day.day);
  final from = DateTime(start.year, start.month, start.day);
  final to = end == null
      ? from
      : DateTime(end.year, end.month, end.day);
  return !target.isBefore(from) && !target.isAfter(to);
}

/// Tek bir tarih ya da bir tarih aralığı ("7-11 Eylül 2026" gibi).
/// [end] `null` ya da [start] ile aynı günse tekil tarih sayılır.
class AcademicDateRange {
  final DateTime start;
  final DateTime? end;

  const AcademicDateRange(this.start, [this.end]);

  bool get isRange => end != null && !_isSameDay(start, end!);

  /// [day] bu aralığın içinde mi (başlangıç ve bitiş dahil).
  bool containsDay(DateTime day) => isDateWithinRange(day, start, end);
}

/// Güz ve Bahar yarıyılındaki karşılık gelen aynı akademik sürecin iki
/// tarihi — kaynak tablo bu şekilde eşleştirilmiş sütunlarla yayınlanıyor
/// (ör. "Derslerin Başlaması": Güz'de 14 Eylül, Bahar'da 1 Şubat).
class AcademicMilestone {
  final String title;
  final AcademicDateRange? fall;
  final AcademicDateRange? spring;

  /// Kaynaktaki dipnot işaretli satırlar için (ör. öğrenci sayısına göre
  /// OBS'de işlem şartı). Sayfa altındaki "Kapsam" notunda açıklanır.
  final bool hasFootnote;

  const AcademicMilestone({
    required this.title,
    this.fall,
    this.spring,
    this.hasFootnote = false,
  });
}

class PublicHoliday {
  final DateTime date;
  final String title;
  final bool halfDay;

  const PublicHoliday({
    required this.date,
    required this.title,
    this.halfDay = false,
  });
}

/// "Sıradaki önemli tarih" kartı için akademik takvim + resmî tatillerin
/// tek bir zaman çizelgesinde birleştirilmiş hali.
///
/// [end] doldurulmuşsa (ör. "7-11 Eylül") olay bir aralıktır; bugün bu
/// aralığın içindeyse [isOngoingOn] `true` döner ve kart "devam ediyor"
/// olarak gösterilir. Resmî tatiller ve tekil günler [end] taşımaz.
class AcademicEvent {
  final DateTime date;
  final DateTime? end;
  final String title;
  final bool isHoliday;

  const AcademicEvent({
    required this.date,
    this.end,
    required this.title,
    this.isHoliday = false,
  });

  bool get isRange => end != null && !_isSameDay(date, end!);

  bool isOngoingOn(DateTime day) => isRange && isDateWithinRange(day, date, end);
}
