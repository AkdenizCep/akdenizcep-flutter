import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final double? avgRating;
  final bool enabled;
  final ValueChanged<int> onStarTap;

  const RatingRow({
    super.key,
    required this.avgRating,
    required this.enabled,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filledCount = avgRating?.round() ?? 0;
    final label = !enabled
        ? 'Puan vermek için giriş yapın'
        : avgRating == null
            ? 'İlk oyu sen ver!'
            : 'Bu yemeği puanla';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    Icons.star_rounded,
                    color: i < filledCount
                        ? colorScheme.secondary
                        : colorScheme.outlineVariant,
                  ),
                  onPressed: enabled ? () => onStarTap(i + 1) : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
