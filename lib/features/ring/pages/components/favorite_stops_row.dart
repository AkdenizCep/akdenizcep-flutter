import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/nav_visibility_provider.dart';
import '../../providers/ring_provider.dart';
import 'ring_format.dart';
import 'stop_detail_sheet.dart';

/// "SIK KULLANILAN DURAKLAR" yatay kart listesi bileşeni.
class FavoriteStopsRow extends ConsumerWidget {
  const FavoriteStopsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final nearbyStops = ref.watch(nearbyStopsProvider);
    final stopsList = nearbyStops.isNotEmpty
        ? nearbyStops
        : _defaultStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'SIK KULLANILAN DURAKLAR',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (int i = 0; i < stopsList.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _StopCard(
                  name: _getStopName(stopsList[i]),
                  timeSubtitle: _getStopSubtitle(stopsList[i], i),
                  onTap: () {
                    final stopId = _getStopId(stopsList[i]);
                    if (stopId != null) {
                      _openStopDetail(context, ref, stopId);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getStopName(dynamic item) {
    if (item is NearbyStop) return item.stop.name;
    if (item is _DummyStop) return item.name;
    return 'Durak';
  }

  String? _getStopId(dynamic item) {
    if (item is NearbyStop) return item.stop.id;
    return null;
  }

  String _getStopSubtitle(dynamic item, int index) {
    if (item is NearbyStop && item.distanceMeters != null) {
      return distanceText(item.distanceMeters!);
    }
    if (item is _DummyStop) return item.subtitle;
    final minutes = (index + 1) * 5 + 2;
    return '$minutes dk sonra';
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

class _StopCard extends StatelessWidget {
  final String name;
  final String timeSubtitle;
  final VoidCallback onTap;

  const _StopCard({
    required this.name,
    required this.timeSubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 175,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timeSubtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DummyStop {
  final String name;
  final String subtitle;
  const _DummyStop(this.name, this.subtitle);
}

const _defaultStops = [
  _DummyStop('Meltem Kapısı', '5 dk sonra'),
  _DummyStop('Rektörlük', '12 dk sonra'),
  _DummyStop('Ziraat Fakültesi', '18 dk sonra'),
];
