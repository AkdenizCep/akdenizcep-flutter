import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../firebase_options.dart';
import '../models/ring_schedule.dart';
import 'ring_schedule_cache.dart';

/// Ring kalkis saatleri — RTDB'nin sorumlulugu artik yalnizca bu.
///
/// Duraklar `StopsService` uzerinden asset'ten okunuyor; `ring_stops` dugumu
/// bu servis tarafindan **okunmuyor**.
class RingService {
  static const _initialLoadTimeout = Duration(seconds: 12);

  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.databaseURL,
  ).ref();
  final RingScheduleCache _cache;

  RingService({RingScheduleCache? cache})
    : _cache = cache ?? RingScheduleCache();

  Stream<List<RingSchedule>> getSchedules() async* {
    final reference = _rtdb.child('ring_schedule');
    final cached = await _cache.load();
    if (cached != null) yield cached;

    // Cache yoksa onValue'in ilk olayini sonsuza kadar beklemek yerine tek
    // seferlik okumayla acilisi tamamla. Hot restart sonrasi native listener
    // yeniden baglanmasa bile sayfa bu Future veya acik bir hatayla sonuclanir.
    if (cached == null) {
      final snapshot = await reference.get().timeout(
        _initialLoadTimeout,
        onTimeout: () => throw Exception(
          'Ring tarifesine ulaşılamadı. İnternet bağlantını kontrol et.',
        ),
      );
      final schedules = _decode(snapshot.value);
      await _cache.save(schedules);
      yield schedules;
    }

    // Ilk ekran cache/get ile hazir; bundan sonraki RTDB olaylari tarifeyi
    // uygulama acikken de guncel tutar.
    await for (final event in reference.onValue) {
      final schedules = _decode(event.snapshot.value);
      await _cache.save(schedules);
      yield schedules;
    }
  }

  List<RingSchedule> _decode(Object? value) {
    final data = value as Map<dynamic, dynamic>?;
    if (data == null) return <RingSchedule>[];

    return data.entries.map((entry) {
      final lineData = Map<String, dynamic>.from(entry.value as Map);
      return RingSchedule.fromJson(entry.key as String, lineData);
    }).toList();
  }
}
