import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ring_provider.dart';

/// Bir duragi favorilere ekleyip cikaran yildiz. Durum
/// [favoriteStopIdsProvider]'dan okunur, dokunus onu yazar.
class FavoriteStarButton extends ConsumerWidget {
  final String stopId;

  /// `true` ise 40x40 yuvarlak kose kutu icinde (durak yapragi);
  /// `false` ise cıplak ikon (harita karti).
  final bool boxed;
  final double iconSize;

  const FavoriteStarButton({
    super.key,
    required this.stopId,
    this.boxed = false,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite = ref.watch(favoriteStopIdsProvider).contains(stopId);

    final icon = Icon(
      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
      size: iconSize,
      color: isFavorite
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    );

    void toggle() =>
        ref.read(favoriteStopIdsProvider.notifier).toggle(stopId);

    final tooltip = isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle';

    if (!boxed) {
      return IconButton(
        onPressed: toggle,
        icon: icon,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      );
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(width: 40, height: 40, child: Center(child: icon)),
        ),
      ),
    );
  }
}
