import 'package:flutter/material.dart';

import '../../models/meal_rating.dart';
import 'cafeteria_card.dart';

/// Gunun puan ozeti: ortalama, yildizlar, oy sayisi ve tek birincil eylem.
class ScoreCard extends StatelessWidget {
  final MealRating? rating;

  /// `false` ise puanlama devre disidir (oturum yok veya menu bos).
  final bool canRate;
  final VoidCallback onRate;

  const ScoreCard({
    super.key,
    required this.rating,
    required this.canRate,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = rating;
    final hasVotes = summary != null && summary.ratingCount > 0;

    return CafeteriaCard(
      child: Row(
        children: [
          if (hasVotes) ...[
            Text(
              summary.avgRating.toStringAsFixed(1).replaceAll('.', ','),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 32,
                height: 0.9,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRow(value: hasVotes ? summary.avgRating : 0),
                const SizedBox(height: 5),
                Text(
                  hasVotes
                      ? '${summary.ratingCount} öğrenci puanladı'
                      : 'Henüz puan verilmedi',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: canRate ? onRate : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 11,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // Temanin varsayilani 14px/w800; bu kartta dugme ikincil bir
              // oge oldugu icin ortalamanin onune gecmemeli.
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              elevation: 6,
              shadowColor: colorScheme.primary.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(hasVotes ? 'Puanla' : 'İlk oyu sen ver'),
          ),
        ],
      ),
    );
  }
}

/// Bes yildizlik gosterge. Sayfanin her yerinde ayni boyut/renk kullanilsin diye
/// ayri bir bilesen.
class StarRow extends StatelessWidget {
  final double value;
  final double size;

  const StarRow({super.key, required this.value, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filled = value.round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i == 4 ? 0 : 1.5),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: i < filled
                ? colorScheme.secondary
                : colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}
