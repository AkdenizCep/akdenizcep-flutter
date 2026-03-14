import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ring_schedule.dart';
import '../services/ring_service.dart';

final ringServiceProvider = Provider((_) => RingService());

final ringSchedulesProvider = StreamProvider<List<RingSchedule>>((ref) {
  return ref.watch(ringServiceProvider).getSchedules();
});
