import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ring_provider.dart';
import 'bus_stop_icon.dart';
import 'line_badge.dart';
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
///
/// Sayfa yatay kenarı (20) bu bileşene aittir: şerit ekran kenarlarına kadar
/// taşar, bu yüzden üst sayfa yatay padding vermemelidir.
class NearbyStopsRow extends ConsumerWidget {
  const NearbyStopsRow({super.key});

  static const _edge = 20.0;

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
          padding: const EdgeInsets.fromLTRB(_edge, 10, _edge - 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'YAKINDAKİ DURAKLAR',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 11.5 * 0.09,
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _edge),
          // Kartların içeriği (mesafe satırı, hat rozetleri) durak durak
          // değiştiği için yükseklikleri de değişir; [IntrinsicHeight] hepsini
          // en uzun kartın boyuna eşitler.
          //
          // `CrossAxisAlignment.stretch` tek başına çalışmaz: şeridin dikey
          // kısıtı sınırsızdır (dikey kaydırma içinde) ve stretch sonsuz
          // yükseklik dayatır; bu, bölümün tamamen görünmez olmasına yol
          // açıyordu.
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
    final lines = ref.watch(availableLinesProvider);
    final soonest = ref.watch(stopSoonestDepartureProvider(nearby.stop.id));
    final distance = nearby.distanceMeters;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNearest
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StopBusIcon(stop: nearby.stop, size: 20),
                  const SizedBox(width: 6),
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
              if (distance != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${distanceText(distance)} · ${walkingTimeText(distance)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (soonest != null)
                Row(
                  children: [
                    Expanded(child: _Countdown(until: soonest.until)),
                    const SizedBox(width: 6),
                    LineBadge(lineCode: soonest.lineCode, lines: lines),
                  ],
                )
              else
                Text(
                  nearby.schedules.isEmpty ? 'Sefer yok' : 'Bugün bitti',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    height: 1.65,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const Spacer(),
              _StopLines(lineNames: nearby.stop.lineNames),
            ],
          ),
        ),
      ),
    );
  }
}

/// "28 dk sonra" — sayı büyük, birim küçük. Bir saati aşan süreler
/// ("15 sa 32 dk sonra") dev rakam düzenine sığmaz; tek satırlık metne düşer.
class _Countdown extends StatelessWidget {
  final Duration until;

  const _Countdown({required this.until});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = countdownParts(until);

    final Widget child;
    if (parts.unit == 'sonra') {
      child = Text(
        '${parts.value} sonra',
        maxLines: 1,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            parts.value,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 28,
              height: 1.1,
              letterSpacing: -0.56,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${parts.unit == 'dakika' ? 'dk' : 'sn'} sonra',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

/// "HATLAR" + duraktan geçen tüm hatların küçük rozetleri.
class _StopLines extends StatelessWidget {
  final List<String> lineNames;

  const _StopLines({required this.lineNames});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (lineNames.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      // 170 px'de iki rozet ~2 px tasar; sigmazsa kucultulur, kirpilmaz.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HATLAR',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 10 * 0.06,
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final name in lineNames) ...[
              const SizedBox(width: 5),
              Container(
                height: 20,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
