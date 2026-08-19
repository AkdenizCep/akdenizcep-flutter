import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/daily_menu.dart';
import 'cafeteria_card.dart';

/// Gunun menusu: ikonsuz duz liste, sagda kalori sutunu, altta toplam.
class MenuCard extends StatelessWidget {
  final List<MenuEntry> entries;
  final DateTime date;

  const MenuCard({super.key, required this.entries, required this.date});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _EmptyMenu(date: date);

    final colorScheme = Theme.of(context).colorScheme;
    final total = MenuEntry.totalCalories(entries);

    return CafeteriaCard(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++)
            _DishRow(entry: entries[i], isLast: i == entries.length - 1),
          if (total != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 13, 0, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'TOPLAM',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern('tr').format(total)} kcal',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  final MenuEntry entry;
  final bool isLast;

  const _DishRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (entry.calories != null) ...[
            const SizedBox(width: 14),
            Text(
              '${entry.calories} kcal',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  final DateTime date;

  const _EmptyMenu({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted = DateFormat('d MMMM', 'tr').format(date);

    return CafeteriaCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      child: Column(
        children: [
          Text(
            'Menü henüz girilmemiş',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$formatted için üniversite bir menü eklemedi.\n'
            'Oklarla başka bir güne geçebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
