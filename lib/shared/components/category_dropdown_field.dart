import 'package:flutter/material.dart';

import '../utils/event_category.dart';

/// Kategori seçimi için ortak dropdown alanı — etkinlik oluşturma ve
/// topluluk ayarları ekranlarında paylaşılır.
class CategoryDropdownField extends StatelessWidget {
  final List<EventCategory> items;
  final EventCategory value;
  final ValueChanged<EventCategory> onChanged;

  const CategoryDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<EventCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategorySheet(items: items, selected: value),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(value.icon, size: 16, color: value.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  final List<EventCategory> items;
  final EventCategory selected;

  const _CategorySheet({required this.items, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'KATEGORİ SEÇ',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final category = items[index];
                final isSelected = category.id == selected.id;
                return ListTile(
                  onTap: () => Navigator.of(context).pop(category),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      category.icon,
                      size: 19,
                      color: category.color,
                    ),
                  ),
                  title: Text(
                    category.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: colorScheme.primary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
