import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/services/ring_schedule_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('son basarili tarifeyi hot restart icin saklar', () async {
    final now = DateTime(2026, 9, 5, 14);
    final cache = RingScheduleCache(now: () => now);
    final schedules = [
      RingSchedule(
        lineId: 'au_102_gidis',
        weekday: const ['08:00', '08:30'],
        weekend: const ['09:00'],
      ),
    ];

    await cache.save(schedules);
    final restored = await cache.load();

    expect(restored, hasLength(1));
    expect(restored!.single.lineId, 'au_102_gidis');
    expect(restored.single.weekday, ['08:00', '08:30']);
  });

  test('24 saatten eski tarifeyi kullanmaz', () async {
    var now = DateTime(2026, 9, 5, 14);
    final cache = RingScheduleCache(now: () => now);
    await cache.save([
      RingSchedule(
        lineId: 'au_102_gidis',
        weekday: const ['08:00'],
        weekend: const [],
      ),
    ]);

    now = now.add(const Duration(hours: 25));

    expect(await cache.load(), isNull);
  });

  test('bozuk cache canli okumayi engellemez', () async {
    SharedPreferences.setMockInitialValues({
      'ring_schedule_cache_v1': '{bozuk-json',
    });
    final cache = RingScheduleCache();

    expect(await cache.load(), isNull);
  });
}
