import 'package:flutter/material.dart';

class SegmentItem<T> {
  final T value;
  final String label;

  const SegmentItem({required this.value, required this.label});
}

/// Yumusak arka planli, kayan secim gostergeli segment kontrolu.
class SoftSegment<T> extends StatelessWidget {
  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final bool compact;

  const SoftSegment({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: compact ? 38 : 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(item.value),
                  child: Center(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 13 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
