import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_event.dart';
import '../services/student_events_service.dart';

final studentEventsServiceProvider =
    Provider((_) => StudentEventsService());

final studentEventsProvider = StreamProvider<List<StudentEvent>>((ref) {
  return ref.watch(studentEventsServiceProvider).getEvents();
});

final studentEventDetailProvider =
    StreamProvider.family<StudentEvent, String>((ref, eventId) {
  return ref.watch(studentEventsServiceProvider).getEvent(eventId);
});
