import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ring_schedule.dart';

/// Son basarili ring tarifesini hot restart ve kisa sureli cevrimdisi
/// kullanim icin saklar.
///
/// Tarife zaman duyarlidir; eski veri sinirsiz kullanilmaz. Canli Firebase
/// baglantisi her acilista devam eder ve cache'i arkada yeniler.
class RingScheduleCache {
  static const _key = 'ring_schedule_cache_v1';
  static const _maxAge = Duration(hours: 24);

  final DateTime Function() _now;

  RingScheduleCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<List<RingSchedule>?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        (json['savedAt'] as num).toInt(),
      );
      if (_now().difference(savedAt) > _maxAge) {
        await preferences.remove(_key);
        return null;
      }

      final schedules = json['schedules'] as Map<String, dynamic>;
      return [
        for (final entry in schedules.entries)
          RingSchedule.fromJson(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          ),
      ];
    } catch (_) {
      // Bozuk/kismi cache uygulamayi bloke etmemeli; canli veri yeniden
      // yazabilsin diye kayit temizlenir.
      await preferences.remove(_key);
      return null;
    }
  }

  Future<void> save(List<RingSchedule> schedules) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode({
        'savedAt': _now().millisecondsSinceEpoch,
        'schedules': {
          for (final schedule in schedules) schedule.lineId: schedule.toJson(),
        },
      }),
    );
  }
}
