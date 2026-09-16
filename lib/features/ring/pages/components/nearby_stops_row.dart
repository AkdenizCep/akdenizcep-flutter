import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ring_departures.dart';
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
          // Hat + yon bilgisini geri sayimla birlikte okunabilir gostermek
          // icin 176px yetersiz kaliyor. Yatay seritte 196px, ikinci karttan
          // bir parca gostermeye devam ederken metni kucultme ihtiyacini
          // ortadan kaldirir.
          width: 196,
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
              _DepartureSummary(
                stopId: nearby.stop.id,
                departures: departures,
                lineNames: lineNames,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karttaki siradaki sefer ozeti.
///
/// Hat + yon geri sayimla ayni bilgi grubundadir; alttaki rozetlerin birinden
/// hangisinin geri sayima ait oldugunu kullanici tahmin etmek zorunda kalmaz.
/// Saatin duraga varis degil, ilk duraktan kalkis saati oldugu acikca yazilir.
class _DepartureSummary extends ConsumerWidget {
  final String stopId;
  final List<StopDeparture> departures;
  final List<String> lineNames;

  const _DepartureSummary({
    required this.stopId,
    required this.departures,
    required this.lineNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final tomorrow = departures.isEmpty
        ? ref.watch(stopTomorrowFirstsProvider(stopId))
        : const <StopDeparture>[];
    final departure = departures.isNotEmpty
        ? departures.first
        : tomorrow.isNotEmpty
        ? tomorrow.first
        : null;

    if (departure == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sefer bulunamadı',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (lineNames.isNotEmpty) ...[
            const SizedBox(height: 9),
            _OtherLines(lines: lineNames, showLabel: false),
          ],
        ],
      );
    }

    final activeLine = lineLabel(departure.lineCode);
    final otherLines = lineNames.where((line) => line != activeLine).toList();
    final isCurrentDayType =
        ref.watch(showWeekendProvider) ==
        RingDepartures.isWeekendDay(ref.watch(nowProvider));
    final isTomorrow = departures.isEmpty && isCurrentDayType;
    final isSchedulePreview = departures.isEmpty && !isCurrentDayType;

    return Semantics(
      container: true,
      label: isTomorrow
          ? 'Sıradaki hat $activeLine, ${departure.direction}. '
                'Yarın ilk duraktan ${departure.time} kalkışı.'
          : isSchedulePreview
          ? 'Sıradaki hat $activeLine, ${departure.direction}. '
                'Görüntülenen tarifede ilk duraktan ${departure.time} kalkışı.'
          : 'Sıradaki hat $activeLine, ${departure.direction}. '
                'İlk duraktan ${departure.time}, '
                '${_countdownSemantics(departure.until)}.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _LineBadge(label: activeLine, isActive: true),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    departure.direction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (isTomorrow)
              Text(
                'Yarın ${departure.time}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (isSchedulePreview)
              Text(
                'İlk kalkış ${departure.time}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              )
            else
              _CountdownValue(until: departure.until),
            const SizedBox(height: 3),
            Text(
              isTomorrow || isSchedulePreview
                  ? 'İlk duraktan kalkış'
                  : 'İlk duraktan ${departure.time}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (otherLines.isNotEmpty) ...[
              const SizedBox(height: 9),
              _OtherLines(lines: otherLines),
            ],
          ],
        ),
      ),
    );
  }

  String _countdownSemantics(Duration until) {
    if (until.inMinutes > 0) return '${until.inMinutes} dakika sonra';
    return '${until.inSeconds.clamp(0, 59)} saniye sonra';
  }
}

class _CountdownValue extends StatelessWidget {
  final Duration until;

  const _CountdownValue({required this.until});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = countdownParts(until);

    // Bir saati asan sureler "1 sa 5 dk" gibi uzun bir metne donusur; kompakt
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

class _OtherLines extends StatelessWidget {
  final List<String> lines;
  final bool showLabel;

  const _OtherLines({required this.lines, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (showLabel) ...[
          Text(
            lines.length == 1 ? 'Diğer hat' : 'Diğer hatlar',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
        ],
        for (var index = 0; index < lines.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          _LineBadge(label: lines[index], isActive: false),
        ],
      ],
    );
  }
}

class _LineBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _LineBadge({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
