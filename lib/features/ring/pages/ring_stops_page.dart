import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../providers/ring_provider.dart';
import 'components/stop_detail_sheet.dart';
import 'components/stop_list_tile.dart';
import 'components/stops_map.dart';

/// Duraklar sayfasi: ustte harita, altta mesafeye gore sirali liste.
///
/// Konum izni yoksa sayfa yine acilir — harita kampuse odaklanir, liste
/// guzergah sirasina gore dizilir ve mesafeler gizlenir.
class RingStopsPage extends ConsumerWidget {
  const RingStopsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final stops = ref.watch(nearbyStopsProvider);
    final hasLocation = ref.watch(userPositionProvider) != null;

    // Veri henuz gelmediyse "durak girilmemis" demek yanlis bilgi olur —
    // yukleme, bos ve hata durumlari ayri ayri karsilanir.
    final stopsAsync = ref.watch(ringStopsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yakındaki Duraklar')),
      body: stops.isEmpty
          ? switch (stopsAsync) {
              AsyncLoading() => const _LoadingView(),
              AsyncError() => const _StopsErrorView(),
              _ => const _NoStopsView(),
            }
          : Column(
              children: [
                SizedBox(
                  height: 240,
                  child: StopsMap(
                    stops: stops.map((s) => s.stop).toList(),
                    onStopTap: (stopId) =>
                        _openStopDetail(context, ref, stopId),
                  ),
                ),
                if (!hasLocation)
                  _EnableLocationBanner(
                    onEnable: () => _requestLocation(context, ref),
                  ),
                Expanded(
                  child: ListView.separated(
                    // Alt kisim yuzen nav bar'in altinda kalmasin.
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      130 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: stops.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            hasLocation ? 'MESAFEYE GÖRE' : 'GÜZERGAH SIRASINA GÖRE',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.6,
                                ),
                          ),
                        );
                      }

                      final nearby = stops[index - 1];
                      return StopListTile(
                        nearby: nearby,
                        onTap: () =>
                            _openStopDetail(context, ref, nearby.stop.id),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _requestLocation(BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(userPositionProvider.notifier).request();
    if (granted || !context.mounted) return;

    final permanentlyDenied = await ref
        .read(userPositionProvider.notifier)
        .isPermanentlyDenied();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          permanentlyDenied
              ? 'Konum izni kapalı. Ayarlardan açabilirsin.'
              : 'Konum alınamadı. Konum servisin açık mı?',
        ),
        action: permanentlyDenied
            ? SnackBarAction(
                label: 'Ayarlar',
                onPressed: () =>
                    ref.read(userPositionProvider.notifier).openSettings(),
              )
            : null,
      ),
    );
  }

  Future<void> _openStopDetail(
    BuildContext context,
    WidgetRef ref,
    String stopId,
  ) async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => StopDetailSheet(stopId: stopId),
      );
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }
}

class _EnableLocationBanner extends StatelessWidget {
  final VoidCallback onEnable;

  const _EnableLocationBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Icon(
            Icons.my_location_rounded,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mesafeleri görmek için konumunu aç.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
            child: const Text('Aç'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Duraklar yükleniyor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsErrorView extends StatelessWidget {
  const _StopsErrorView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Durak bilgisi alınamadı.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Bağlantını kontrol edip tekrar dene.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStopsView extends StatelessWidget {
  const _NoStopsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Durak bilgisi henüz girilmemiş.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
