import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/stop_departures.dart';
import '../../providers/ring_provider.dart';
import 'open_stop_detail.dart';
import 'open_stops_page.dart';
import 'ring_format.dart';

/// "YAKINDAKİ DURAKLAR" yatay kart şeridi.
///
/// Veri yoksa bölüm hiç çizilmez — sahte durak göstermek, kullanıcıyı olmayan
/// bir durağa yönlendirmek demek olurdu.
///
/// ÖNEMLİ: Karttaki geri sayım, hattın **kalkış noktasından** ayrılmasına kalan
/// süredir; otobüsün bu durağa ulaşma süresi değildir.
class NearbyStopsRow extends ConsumerWidget {
  const NearbyStopsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final stops = ref.watch(nearbyStopsProvider);
    if (stops.isEmpty) return const SizedBox.shrink();

    final nearestId = ref.watch(nearestStopProvider)?.stop.id;
    final visible = stops.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'YAKINDAKİ DURAKLAR',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.04,
                  ),
                ),
              ),
              InkWell(
                onTap: () => openStopsPage(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Tümü',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          // Kartlarin icerigi (mesafe satiri, hat rozetleri) durak durak
          // degistigi icin yukseklikleri de degisir; [IntrinsicHeight] hepsini
          // en uzun kartin boyuna esitler.
          //
          // `CrossAxisAlignment.stretch` tek basina calismaz: seridin dikey
          // kisiti sinirsizdir (dikey kaydirma icinde) ve stretch sonsuz
          // yukseklik dayatir. Bu, layout'u patlatip bolumun tamamen
          // gorunmez olmasina yol aciyordu.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _NearbyStopCard(
                    nearby: visible[i],
                    isNearest: visible[i].stop.id == nearestId,
                    onTap: () =>
                        openStopDetail(context, ref, visible[i].stop.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NearbyStopCard extends ConsumerWidget {
  final NearbyStop nearby;
  final bool isNearest;
  final VoidCallback onTap;

  const _NearbyStopCard({
    required this.nearby,
    required this.isNearest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final departures = ref.watch(stopDeparturesProvider(nearby.stop.id));
    final lineNames = nearby.stop.lineNames;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 176,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNearest
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isNearest
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      nearby.stop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (nearby.distanceMeters != null) ...[
                const SizedBox(height: 5),
                Text(
                  '${distanceText(nearby.distanceMeters!)} · '
                  '${walkingTimeText(nearby.distanceMeters!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _Countdown(stopId: nearby.stop.id, departures: departures),
              if (lineNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(

                  children: [
                    for (final code in lineNames)
                      Container(
                        height: 22,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Karttaki geri sayım. Bugün sefer kalmadıysa yarının ilk kalkışına düşer.
class _Countdown extends ConsumerWidget {
  final String stopId;
  final List<StopDeparture> departures;

  const _Countdown({required this.stopId, required this.departures});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (departures.isEmpty) {
      final tomorrow = ref.watch(stopTomorrowFirstsProvider(stopId));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bugün bitti',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (tomorrow.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Yarın ilk kalkış ${tomorrow.first.time}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    final parts = countdownParts(departures.first.until);

    // Bir saati asan sureler "1 sa 5 dk" gibi uzun bir metne donusur; 176px
    // kartta dev rakam duzeni tasar. O durumda tek satirlik kucuk metne dusulur.
    if (parts.unit == 'sonra') {
      return Text(
        '${parts.value} sonra',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          parts.value,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${parts.unit == 'dakika' ? 'dk' : 'sn'} sonra',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
