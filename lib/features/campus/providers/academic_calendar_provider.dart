import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/academic_calendar.dart';
import '../services/academic_calendar_service.dart';

final academicCalendarServiceProvider = Provider(
  (_) => AcademicCalendarService(),
);

final academicMilestonesProvider = Provider<List<AcademicMilestone>>((ref) {
  return ref.watch(academicCalendarServiceProvider).milestones;
});

final publicHolidaysProvider = Provider<List<PublicHoliday>>((ref) {
  return ref.watch(academicCalendarServiceProvider).holidays;
});

/// Sayfa hangi yarıyılı göstererek açılsın — bugüne göre makul bir varsayım.
final selectedAcademicTermProvider = StateProvider<AcademicTerm>((ref) {
  return ref.watch(academicCalendarServiceProvider).currentTerm(DateTime.now());
});

/// Bugünden itibaren en yakın akademik dönüm noktası ya da resmî tatil.
/// Takvim yılı bittiğinde (tüm tarihler geçmişte kalınca) `null` döner.
final nextAcademicEventProvider = Provider<AcademicEvent?>((ref) {
  final events = ref
      .watch(academicCalendarServiceProvider)
      .upcomingEvents(DateTime.now());
  return events.isEmpty ? null : events.first;
});
