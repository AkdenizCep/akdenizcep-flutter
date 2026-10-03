import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/event_feed_provider.dart';
import '../../../../shared/utils/event_category.dart';

/// 2a kategori şeridi — tek seçim, anında filtreleme.
class CategoryStrip extends ConsumerWidget {
  const CategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedCategoryProvider);

    return SizedBox(
      // 62px kutu + 8 boşluk + etiket satırı; üst/alt payı seçilideki 5px
      // halkanın kırpılmaması için bırakıldı.
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
        itemCount: EventCategory.stripItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = EventCategory.stripItems[index];
          return _CategoryItem(
            category: category,
            selected: category.id == selectedId,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state =
                category.id,
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seçilideki 3px yüzey + 5px kategori halkası yerleşimi büyütmesin
            // diye gölge olarak çizilir (kutunun dışına taşar).
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: selected
                    ? category.color
                    : category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? null
                    : Border.all(color: colorScheme.outlineVariant),
                boxShadow: selected
                    ? [
                        BoxShadow(color: category.color, spreadRadius: 5),
                        BoxShadow(
                          color: colorScheme.surface,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                category.icon,
                size: 26,
                color: selected ? Colors.white : category.color,
              ),
            ),
            const SizedBox(height: 8),
            // Cihazda büyük yazı tipi seçiliyse etiket şeridi taşırmasın.
            Flexible(
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
