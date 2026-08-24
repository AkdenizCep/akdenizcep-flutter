import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ring_provider.dart';
import 'favorite_star_button.dart';
import 'ring_format.dart';

/// Harita ekranının altındaki yatay şeritte duran durak kartı.
///
/// Bilinçli olarak kompakt: durak kimliği, mesafe, geçen hatlar ve iki aksiyon.
/// Kalkış saatleri buraya sığdırılmaz — kart şeridi haritanın üstünde durduğu
/// için yükseldikçe haritayı yiyor. Saatler "Hatları gör" ile açılan durak
/// yaprağında, tam kronolojik listeyle gösterilir.
class StopMapCard extends ConsumerWidget {
  final NearbyStop nearby;
  final bool isSelected;

  /// "Hatları gör" — durak yaprağını açar.
  final VoidCallback onShowLines;

  /// Yürüme yol tarifi — harici harita uygulamasını açar.
  final VoidCallback onWalkingDirections;

  const StopMapCard({
    super.key,
    required this.nearby,
    required this.isSelected,
    required this.onShowLines,
    required this.onWalkingDirections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Hat uyeligi duragin kendi verisinde; RTDB tarifesi gelmese de dogru.
    final lineNames = nearby.stop.lineNames;
    final sideNote = stopSideNote(nearby.stop);

    return Container(
      width: 274,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.20 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 21,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nearby.stop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (nearby.distanceMeters != null || sideNote != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (nearby.distanceMeters != null)
                            '${distanceText(nearby.distanceMeters!)} · '
                                '${walkingTimeText(nearby.distanceMeters!)}',
                          ?sideNote,
                        ].join(' · '),
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
                ),
              ),
              FavoriteStarButton(stopId: nearby.stop.id),
            ],
          ),
          if (lineNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 24,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: lineNames.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) => Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lineNames[index],
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: onShowLines,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Hatları gör'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: onWalkingDirections,
                  borderRadius: BorderRadius.circular(15),
                  child: Tooltip(
                    message: 'Yürüme yol tarifi',
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.directions_walk_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
