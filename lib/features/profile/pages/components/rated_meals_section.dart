import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/error_message.dart';
import '../../models/profile_rated_meal.dart';
import '../../providers/profile_provider.dart';

class RatedMealsSection extends ConsumerWidget {
  const RatedMealsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(myRatedMealsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return mealsAsync.when(
      data: (meals) {
        if (meals.isEmpty) {
          return Text(
            'Henüz bir yemeğe puan vermedin.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < meals.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RatedMealTile(meal: meals[i]),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(
        errorMessage(e),
        style: TextStyle(color: colorScheme.error, fontSize: 12),
      ),
    );
  }
}

class _RatedMealTile extends StatelessWidget {
  final ProfileRatedMeal meal;

  const _RatedMealTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsedDate = DateTime.tryParse(meal.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  parsedDate != null
                      ? DateFormat('d MMMM yyyy', 'tr').format(parsedDate)
                      : meal.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (parsedDate != null)
                Text(
                  DateFormat('EEEE', 'tr').format(parsedDate),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                Icons.star_rounded,
                size: 16,
                color: i < meal.rating
                    ? colorScheme.secondary
                    : colorScheme.outlineVariant,
              );
            }),
          ),
          if (meal.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meal.comment,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
