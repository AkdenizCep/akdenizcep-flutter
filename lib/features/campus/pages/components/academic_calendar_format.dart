import 'package:intl/intl.dart';

import '../../models/academic_calendar.dart';

/// "7-11 Eylül 2026" / "14 Eylül - 20 Aralık 2026" / "1 Şubat 2027" gibi
/// biçimlendirir. [range] `null` ise "—" döner (bu takvimde hiçbir satırda
/// olmuyor ama tip güvenliği için).
String formatAcademicRange(AcademicDateRange? range) {
  if (range == null) return '—';
  if (!range.isRange) {
    return DateFormat('d MMMM yyyy', 'tr').format(range.start);
  }

  final start = range.start;
  final end = range.end!;

  if (start.year == end.year && start.month == end.month) {
    return '${start.day}-${end.day} ${DateFormat('MMMM yyyy', 'tr').format(end)}';
  }
  return '${DateFormat('d MMMM', 'tr').format(start)} - '
      '${DateFormat('d MMMM yyyy', 'tr').format(end)}';
}

String formatHolidayDate(DateTime date) =>
    DateFormat('d MMMM yyyy, EEEE', 'tr').format(date);

String formatShortDate(DateTime date) =>
    DateFormat('d MMMM yyyy', 'tr').format(date);
