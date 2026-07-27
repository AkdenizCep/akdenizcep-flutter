import 'package:flutter/material.dart';

import '../../models/menu_item.dart';

class MealVisualStyle {
  final Color color;
  final IconData icon;

  const MealVisualStyle({required this.color, required this.icon});

  factory MealVisualStyle.fromType(String mealType) {
    final normalized = mealType.toLowerCase();

    if (normalized.contains('kahvalt')) {
      return const MealVisualStyle(
        color: Color(0xFFE8A317),
        icon: Icons.free_breakfast_rounded,
      );
    }
    if (normalized.contains('akşam') || normalized.contains('aksam')) {
      return const MealVisualStyle(
        color: Color(0xFF5C4FE0),
        icon: Icons.dinner_dining_rounded,
      );
    }

    return const MealVisualStyle(
      color: Color(0xFF135BEC),
      icon: Icons.lunch_dining_rounded,
    );
  }
}

IconData _iconForMealItem(String label, IconData fallback) {
  final normalized = label.toLowerCase();

  if (normalized.contains('çorba') || normalized.contains('corba')) {
    return Icons.soup_kitchen_rounded;
  }
  if (normalized.contains('salata')) {
    return Icons.eco_rounded;
  }
  if (normalized.contains('tatlı') ||
      normalized.contains('tatli') ||
      normalized.contains('baklava') ||
      normalized.contains('sütlaç') ||
      normalized.contains('sutlac') ||
      normalized.contains('dondurma') ||
      normalized.contains('kek')) {
    return Icons.icecream_rounded;
  }
  if (normalized.contains('pilav') || normalized.contains('bulgur')) {
    return Icons.rice_bowl_rounded;
  }
  if (normalized.contains('makarna') ||
      normalized.contains('erişte') ||
      normalized.contains('eriste')) {
    return Icons.ramen_dining_rounded;
  }
  if (normalized.contains('balık') || normalized.contains('balik')) {
    return Icons.set_meal_rounded;
  }
  if (normalized.contains('yumurta')) {
    return Icons.egg_alt_rounded;
  }
  if (normalized.contains('ekmek')) {
    return Icons.bakery_dining_rounded;
  }
  if (normalized.contains('ayran') ||
      normalized.contains('yoğurt') ||
      normalized.contains('yogurt')) {
    return Icons.local_drink_rounded;
  }

  return fallback;
}

final _calorieSuffixPattern = RegExp(
  r'^(.*?)\s*-\s*(\d+)\s*kcal$',
  caseSensitive: false,
);

({String name, int? calories}) _parseMealItem(String raw) {
  final match = _calorieSuffixPattern.firstMatch(raw.trim());
  if (match == null) return (name: raw, calories: null);

  return (name: match.group(1)!.trim(), calories: int.parse(match.group(2)!));
}

class MealHeroCard extends StatelessWidget {
  final MenuItem menu;
  final double? avgRating;
  final int ratingCount;

  const MealHeroCard({
    super.key,
    required this.menu,
    required this.avgRating,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final style = MealVisualStyle.fromType(menu.mealType);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -12,
            child: Icon(
              style.icon,
              size: 142,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.mealType.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    if (avgRating != null)
                      _RatingBadge(
                        avgRating: avgRating!,
                        ratingCount: ratingCount,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (menu.items.isEmpty)
                  Text(
                    'Bu öğün için yemek bilgisi girilmemiş.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < menu.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        () {
                          final parsedItem = _parseMealItem(menu.items[i]);
                          return _MealItemRow(
                            item: parsedItem,
                            icon: _iconForMealItem(parsedItem.name, style.icon),
                          );
                        }(),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double avgRating;
  final int ratingCount;

  const _RatingBadge({required this.avgRating, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            avgRating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($ratingCount oy)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItemRow extends StatelessWidget {
  final ({String name, int? calories}) item;
  final IconData icon;

  const _MealItemRow({required this.item, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (item.calories != null) ...[
            const SizedBox(width: 8),
            _CalorieBadge(calories: item.calories!),
          ],
        ],
      ),
    );
  }
}

class _CalorieBadge extends StatelessWidget {
  final int calories;

  const _CalorieBadge({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            '$calories kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
