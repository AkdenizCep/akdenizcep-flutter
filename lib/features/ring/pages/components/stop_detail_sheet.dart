import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ring_departures.dart';
import '../../providers/ring_provider.dart';
import 'ring_format.dart';

/// Bir duragin detayi: buradan gecen hatlar ve her hattin siradaki kalkisi.
///
/// ONEMLI: Universite durak bazli saat yayinlamiyor. Bu yuzden gosterilen
/// her saat hattin **kalkis noktasindan** ayrilma zamanidir; bu duraga varis
/// zamani degildir. Dil bu ayrimi korumali — "varış", "gelir" gibi ifadeler
/// kullanilmamalidir.
class StopDetailSheet extends ConsumerWidget {
  final String stopId;

  const StopDetailSheet({super.key, required this.stopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final nearbyStops = ref.watch(nearbyStopsProvider);
    final match = nearbyStops.where((s) => s.stop.id == stopId);
    if (match.isEmpty) return const SizedBox.shrink();

    final nearby = match.first;
    final now = ref.watch(nowProvider);
    final showWeekend = ref.watch(showWeekendProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nearby.stop.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (nearby.distanceMeters != null)
                  Text(
                    distanceText(nearby.distanceMeters!),
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            if (nearby.distanceMeters != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: Text(
                  walkingTimeText(nearby.distanceMeters!),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            if (nearby.schedules.isEmpty)
              Text(
                'Bu duraktan geçen hat bilgisi girilmemiş.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                'BURADAN GEÇEN HATLAR',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              for (final schedule in nearby.schedules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LineDepartureCard(
                    lineCode: schedule.lineCode,
                    direction: directionSummary(
                      schedule,
                      ref.watch(ringStopMapProvider),
                    ),
                    departures: RingDepartures.from(
                      weekdayTimes: schedule.weekday,
                      weekendTimes: schedule.weekend,
                      showWeekend: showWeekend,
                      now: now,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saatler hattın kalkış noktasına aittir.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDepartureCard extends StatelessWidget {
  final String lineCode;
  final String direction;
  final RingDepartures departures;

  const _LineDepartureCard({
    required this.lineCode,
    required this.direction,
    required this.departures,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lineLabel(lineCode),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  direction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDepartureLine(context),
        ],
      ),
    );
  }

  Widget _buildDepartureLine(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (departures.times.isEmpty) {
      return Text(
        'Bu gün için sefer saati girilmemiş.',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (!departures.isToday) {
      return Text(
        'İlk kalkış ${departures.times.first}',
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      );
    }

    if (departures.nextTime == null) {
      final tomorrow = departures.tomorrowFirstTime;
      return Text(
        tomorrow == null
            ? 'Bugün için başka kalkış yok.'
            : 'Bugün bitti · Yarın ilk kalkış $tomorrow',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final rest = departures.upcoming.length > 1
        ? departures.upcoming.sublist(1).take(2).join(' · ')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sıradaki kalkış',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              departures.nextTime!,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countdownText(departures.untilNext!),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        if (rest != null) ...[
          const SizedBox(height: 6),
          Text(
            'Sonrası: $rest',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
