import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/stop_departures.dart';
import '../../providers/ring_provider.dart';
import 'favorite_star_button.dart';
import 'ring_format.dart';

/// Bir durağın detayı: buradan geçen tüm hatların kalkışları **tek kronolojik
/// listede**, hat/yön grubu olmadan.
///
/// ÖNEMLİ: Üniversite durak bazlı saat yayınlamıyor. Bu yüzden gösterilen
/// her saat hattın **kalkış noktasından** ayrılma zamanıdır; bu durağa varış
/// zamanı değildir. Dil bu ayrımı korumalı — "varış", "gelir", "otobüs burada
/// olur" gibi ifadeler kullanılmamalıdır.
class StopDetailSheet extends ConsumerWidget {
  final String stopId;
  final VoidCallback? onShowOnMap;

  const StopDetailSheet({super.key, required this.stopId, this.onShowOnMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final nearbyStops = ref.watch(nearbyStopsProvider);
    final match = nearbyStops.where((s) => s.stop.id == stopId);
    if (match.isEmpty) return const SizedBox.shrink();

    final nearby = match.first;
    final departures = ref.watch(stopDeparturesProvider(stopId));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık bloğu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nearby.stop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (nearby.distanceMeters != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${distanceText(nearby.distanceMeters!)} · '
                            '${walkingTimeText(nearby.distanceMeters!)}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FavoriteStarButton(stopId: stopId, boxed: true, iconSize: 20),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: nearby.schedules.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Bu duraktan geçen hat bilgisi girilmemiş.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : departures.isEmpty
                    ? _FinishedForToday(stopId: stopId)
                    : _DepartureList(departures: departures),
              ),
            ),

            // Dil kuralı: bu not her listede kalır.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
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
            ),
            if (onShowOnMap != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onShowOnMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Haritada Göster'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.04,
        ),
      ),
    );
  }
}

/// Bugün kalan kalkışlar — hat/yön ayrımı yapmadan zamana göre tek liste.
class _DepartureList extends StatelessWidget {
  final List<StopDeparture> departures;

  const _DepartureList({required this.departures});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('SIRADAKİ KALKIŞLAR'),
        for (var i = 0; i < departures.length; i++)
          _DepartureRow(departure: departures[i], isNext: i == 0),
      ],
    );
  }
}

/// Bugün sefer kalmadığında: aynı satır düzeni, geri sayım alanında saat.
class _FinishedForToday extends ConsumerWidget {
  final String stopId;

  const _FinishedForToday({required this.stopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tomorrow = ref.watch(stopTomorrowFirstsProvider(stopId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('BUGÜNÜN SEFERLERİ BİTTİ'),
        if (tomorrow.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Bu gün için sefer saati girilmemiş.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          for (final departure in tomorrow)
            _DepartureRow(
              departure: departure,
              isNext: false,
              isTomorrow: true,
            ),
      ],
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final StopDeparture departure;

  /// İlk satır vurgulanır — kullanıcının aradığı tek bilgi genelde budur.
  final bool isNext;

  /// Yarının ilk kalkışı: geri sayım yerine saatin kendisi gösterilir.
  final bool isTomorrow;

  const _DepartureRow({
    required this.departure,
    required this.isNext,
    this.isTomorrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: _Countdown(
              departure: departure,
              isNext: isNext,
              isTomorrow: isTomorrow,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      height: 23,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isNext
                            ? colorScheme.primary
                            : colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lineLabel(departure.lineCode),
                        style: TextStyle(
                          color: isNext
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        departure.direction,
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
                const SizedBox(height: 5),
                Text(
                  _timesLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _timesLine {
    if (isTomorrow) return 'Yarın ilk kalkış ${departure.time}';
    if (departure.nextTwo.isEmpty) return departure.time;
    return '${departure.time} · sonrası ${departure.nextTwo.join(' · ')}';
  }
}

/// Satırın solundaki dev geri sayım.
class _Countdown extends StatelessWidget {
  final StopDeparture departure;
  final bool isNext;
  final bool isTomorrow;

  const _Countdown({
    required this.departure,
    required this.isNext,
    required this.isTomorrow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final valueColor = isNext ? colorScheme.primary : colorScheme.onSurface;
    final unitColor = isNext
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    // Yarının kalkışında geri sayım anlamsız — saatin kendisi yazılır.
    final parts = isTomorrow
        ? (value: departure.time, unit: 'YARIN')
        : countdownParts(departure.until);

    // "1 sa 5 dk" gibi uzun değerler dev punto ile 58px'e sığmaz.
    final isLong = parts.unit == 'sonra' || isTomorrow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parts.value,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: valueColor,
            fontSize: isLong ? 18 : 26,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          switch (parts.unit) {
            'sonra' => 'SONRA',
            'dakika' => 'DAKİKA',
            'saniye' => 'SANİYE',
            final other => other,
          },
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: unitColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
