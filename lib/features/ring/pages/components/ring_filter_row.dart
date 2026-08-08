import 'package:flutter/material.dart';

import 'ring_format.dart';
import 'soft_segment.dart';

/// Hat secici + gun tipi anahtari.
class RingFilterRow extends StatelessWidget {
  final List<String> lines;
  final String activeLine;
  final bool showWeekend;
  final ValueChanged<String> onLineChanged;
  final ValueChanged<bool> onDayChanged;

  const RingFilterRow({
    super.key,
    required this.lines,
    required this.activeLine,
    required this.showWeekend,
    required this.onLineChanged,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (lines.length > 1)
          Expanded(
            child: SoftSegment<String>(
              compact: true,
              selectedValue: activeLine,
              onChanged: onLineChanged,
              items: [
                for (final line in lines)
                  SegmentItem(value: line, label: lineLabel(line)),
              ],
            ),
          )
        else
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lineLabel(activeLine),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        _DayToggle(showWeekend: showWeekend, onChanged: onDayChanged),
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  final bool showWeekend;
  final ValueChanged<bool> onChanged;

  const _DayToggle({required this.showWeekend, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Hafta sonu tarifesi belirgin sekilde farkli olabilir; ikincil renkle
    // ayrisir. Sabit renk yerine tema kullanilir ki karanlik temada da okunsun.
    final background = showWeekend
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final foreground = showWeekend
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: 'Gün tipi: ${dayTypeLabel(showWeekend)}. Değiştirmek için dokun.',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => onChanged(!showWeekend),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: foreground,
                ),
                const SizedBox(width: 6),
                Text(
                  shortDayTypeLabel(showWeekend),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
