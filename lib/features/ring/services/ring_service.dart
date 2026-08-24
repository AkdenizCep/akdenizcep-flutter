import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../firebase_options.dart';
import '../models/ring_schedule.dart';

/// Ring kalkis saatleri — RTDB'nin sorumlulugu artik yalnizca bu.
///
/// Duraklar `StopsService` uzerinden asset'ten okunuyor; `ring_stops` dugumu
/// bu servis tarafindan **okunmuyor**.
class RingService {
  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.databaseURL,
  ).ref();

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
