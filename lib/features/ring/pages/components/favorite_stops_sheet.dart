import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/nav_visibility_provider.dart';
import '../../providers/ring_provider.dart';
import 'open_stop_detail.dart';
import 'stop_list_tile.dart';

/// Arama satirinin sagindaki yildiz butonunun actigi yaprak: favori duraklar.
class FavoriteStopsSheet extends ConsumerWidget {
  const FavoriteStopsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favorites = ref.watch(favoriteStopsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Favori Duraklar',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'Henüz favori durağın yok — bir durağın yanındaki yıldıza dokun.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final nearby = favorites[index];
                    // Yaprak secilen durak id'siyle kapanir; durak yapragini
                    // acmak cagirana birakilir — boylece iki yaprak ust uste
                    // binmez.
                    return StopListTile(
                      nearby: nearby,
                      onTap: () => Navigator.of(context).pop(nearby.stop.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Favori yapragini acar. Yaprak acikken yuzen nav bar gizlenir.
Future<void> openFavoriteStopsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  ref.read(bottomNavVisibleProvider.notifier).state = false;
  String? selected;
  try {
    selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => const FavoriteStopsSheet(),
    );
  } finally {
    ref.read(bottomNavVisibleProvider.notifier).state = true;
  }

  if (selected == null || !context.mounted) return;
  await openStopDetail(context, ref, selected);
}
