import 'package:flutter/material.dart';

import '../models/category_option.dart';

/// Kategori seçimi için ortak dropdown alanı — etkinlik oluşturma, topluluk
/// ayarları ve kayıp/buluntu ilanı ekranlarında paylaşılır. [T], `label`/
/// `color`/`icon` sağlayan herhangi bir [CategoryOption] katalog tipi olabilir.
class CategoryDropdownField<T extends CategoryOption> extends StatelessWidget {
  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;

  const CategoryDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategorySheet<T>(items: items, selected: value),
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
              Icon(value.icon, size: 20, color: value.color),
              const SizedBox(width: 12),
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

class _CategorySheet<T extends CategoryOption> extends StatelessWidget {
  final List<T> items;
  final T selected;

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
          // ListView.shrinkWrap yerine duz Column: katalog hep sabit ve kisa
          // (en fazla 7-8 oge), kaydirilabilir bir liste hic gerekmiyor.
          // ListView + Flexible/shrinkWrap kombinasyonu icerigin altinda
          // beklenmedik bosluk birakiyordu; duz Column'da bosluk ihtimali yok
          // — sayfa tam olarak cocuklarinin toplam yuksekligi kadar yer kaplar.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final category in items)
                    _CategoryRow(
                      category: category,
                      isSelected: category.id == selected.id,
                      onTap: () => Navigator.of(context).pop(category),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Renk yalnizca secili satirda tasiyici — geri kalani notr. Her satirin
    // kendi renkli kutucugu olunca liste bir "renk paleti"ne donusuyordu;
    // artik renk anlam tasiyor (secili olan), dekor olarak tekrar etmiyor.
    return Material(
      color: isSelected
          ? category.color.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          category.icon,
          size: 22,
          color: isSelected ? category.color : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          category.label,
          style: TextStyle(
            color: isSelected ? category.color : null,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_rounded, color: category.color)
            : null,
      ),
    );
  }
}
