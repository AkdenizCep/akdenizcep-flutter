import 'package:flutter/material.dart';

import '../../models/campus_location.dart';
import 'map_category_style.dart';

class MapSearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final LocationCategory? selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onBack;

  const MapSearchPanel({
    super.key,
    required this.controller,
    required this.query,
    required this.selectedCategory,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onClearQuery,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelContent(
      controller: controller,
      query: query,
      selectedCategory: selectedCategory,
      onQueryChanged: onQueryChanged,
      onCategoryChanged: onCategoryChanged,
      onClearQuery: onClearQuery,
      onBack: onBack,
    );
  }
}

class _PanelContent extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final LocationCategory? selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<LocationCategory?> onCategoryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onBack;

  const _PanelContent({
    required this.controller,
    required this.query,
    required this.selectedCategory,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onClearQuery,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Geri',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Kampüste konum ara...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: query.isEmpty
                        ? Padding(
                            key: const ValueKey('search'),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.search_rounded,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('clear'),
                            tooltip: 'Aramayı temizle',
                            onPressed: onClearQuery,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(
                label: 'Tümü',
                icon: Icons.apps_rounded,
                color: colorScheme.primary,
                selected: selectedCategory == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final category in LocationCategory.values)
                _CategoryChip(
                  label: category.label,
                  icon: category.icon,
                  color: category.color(colorScheme),
                  selected: selectedCategory == category,
                  onTap: () => onCategoryChanged(category),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? color : colorScheme.surface,
          borderRadius: BorderRadius.circular(19),
          border: selected
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.68),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: selected ? Colors.white : color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
