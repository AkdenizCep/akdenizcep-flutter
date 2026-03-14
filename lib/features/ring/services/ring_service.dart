import 'package:firebase_database/firebase_database.dart';

import '../models/ring_schedule.dart';

class RingService {
  final _rtdb = FirebaseDatabase.instance.ref();

  Stream<List<RingSchedule>> getSchedules() {
    return _rtdb.child('ring_schedule').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <RingSchedule>[];

      return data.entries.map((entry) {
        final lineData = Map<String, dynamic>.from(entry.value as Map);
        return RingSchedule.fromJson(entry.key as String, lineData);
      }).toList();
    });
  }
}
