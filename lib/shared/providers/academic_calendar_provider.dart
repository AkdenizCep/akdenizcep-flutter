import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/academic_calendar_service.dart';

/// Akademik takvim verisinin tek kaynağı. Kampüs ve Ana Sayfa feature'ları
/// birbirini import edemediği için servis burada, `shared/` altında durur.
final academicCalendarServiceProvider = Provider(
  (_) => AcademicCalendarService(),
);
