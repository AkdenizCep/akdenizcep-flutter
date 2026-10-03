/// Günün dilimi: ana sayfadaki selam metnini belirler.
enum DayPart {
  morning('Günaydın'),
  afternoon('İyi günler'),
  evening('İyi akşamlar'),
  night('İyi geceler');

  final String greeting;

  const DayPart(this.greeting);

  /// 05-12 sabah, 12-18 öğleden sonra, 18-22 akşam, 22-05 gece.
  static DayPart at(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return DayPart.morning;
    if (hour >= 12 && hour < 18) return DayPart.afternoon;
    if (hour >= 18 && hour < 22) return DayPart.evening;
    return DayPart.night;
  }
}
