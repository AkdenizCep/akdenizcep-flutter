import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/nav_visibility_provider.dart';
import '../../models/ring_departures.dart';
import '../../providers/ring_provider.dart';
import 'line_badge.dart';
import 'ring_format.dart';

/// "Tüm Tarife" yaprağını açar. Nav bar yaprak nasıl kapanırsa kapansın geri
/// gelir (`finally`).
Future<void> openTimetableSheet(BuildContext context, WidgetRef ref) async {
  final colorScheme = Theme.of(context).colorScheme;
  final height = MediaQuery.of(context).size.height - 78;

  ref.read(bottomNavVisibleProvider.notifier).state = false;
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      constraints: BoxConstraints(maxHeight: height),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => SizedBox(height: height, child: const TimetableSheet()),
    );
  } finally {
    ref.read(bottomNavVisibleProvider.notifier).state = true;
  }
}

/// Kalkış noktası başına iki hattın tam tarifesi, yan yana sütunlarda.
///
/// Tüm saatler kalkış noktasından ayrılma saatidir. Sütunlar birbirinden
/// bağımsızdır; satırların hizalı olması gerekmez.
class TimetableSheet extends ConsumerWidget {
  const TimetableSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final points = ref.watch(departurePointsProvider);
    final point = ref.watch(timetableActivePointProvider);
    final showWeekend = ref.watch(timetableWeekendProvider);
    final lines = ref.watch(availableLinesProvider);
    final now = ref.watch(nowProvider);

    final columns = [
      if (point != null)
        for (final schedule in point.schedules)
          (
            schedule: schedule,
            departures: RingDepartures.from(
              weekdayTimes: schedule.weekday,
              weekendTimes: schedule.weekend,
              showWeekend: showWeekend,
              now: now,
            ),
          ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tüm Tarife',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Material(
                color: colorScheme.surfaceContainer,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _Segment<String>(
                height: 40,
                selected: point?.name,
                onChanged: (name) =>
                    ref.read(timetablePointProvider.notifier).state = name,
                items: [
                  for (final p in points)
                    (
                      value: p.name,
                      label: p.name,
                      icon: Icons.location_on_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Segment<bool>(
                height: 34,
                selected: showWeekend,
                onChanged: (value) =>
                    ref.read(timetableWeekendProvider.notifier).state = value,
                items: const [
                  (value: false, label: 'Hafta içi', icon: null),
                  (value: true, label: 'Hafta sonu', icon: null),
                ],
              ),
            ],
          ),
        ),
        if (columns.isEmpty)
          const Expanded(child: _EmptyTimetable())
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _ColumnHeader(
                      lineCode: columns[i].schedule.lineCode,
                      lines: lines,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                34 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _TimeColumn(
                            lineCode: columns[i].schedule.lineCode,
                            lines: lines,
                            departures: columns[i].departures,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Saatler kalkış noktasına aittir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

typedef _SegmentItem<T> = ({T value, String label, IconData? icon});

/// İki (ya da daha fazla) seçenekli segment kontrol.
class _Segment<T> extends StatelessWidget {
  final double height;
  final T? selected;
  final ValueChanged<T> onChanged;
  final List<_SegmentItem<T>> items;

  const _Segment({
    required this.height,
    required this.selected,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(item.value),
                child: Container(
                  alignment: Alignment.center,
                  decoration: item.value == selected
                      ? BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 16,
                          color: item.value == selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.value == selected
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Düz başlık: hat adı + 3px hat renginde çizgi. Kutu/dolgu/rozet yok.
class _ColumnHeader extends StatelessWidget {
  final String lineCode;
  final List<String> lines;

  const _ColumnHeader({required this.lineCode, required this.lines});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = lineColors(colorScheme, lines, lineCode).fill;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          lineLabel(lineCode),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

enum _CellState { past, next, last, normal }

/// Bir hattın saatleri, saat dilimine göre gruplu.
class _TimeColumn extends StatelessWidget {
  final String lineCode;
  final List<String> lines;
  final RingDepartures departures;

  const _TimeColumn({
    required this.lineCode,
    required this.lines,
    required this.departures,
  });

  _CellState _stateOf(String time) {
    final times = departures.times;
    if (departures.isToday) {
      if (time == departures.nextTime) return _CellState.next;
      final next = departures.nextTime;
      if (next == null || time.compareTo(next) < 0) return _CellState.past;
    }
    if (times.isNotEmpty && time == times.last) return _CellState.last;
    return _CellState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final times = departures.times;

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Column(
        spacing: 3,
        children: [
          for (final time in times)
            _TimeCell(
              time: time,
              state: _stateOf(time),
              lineCode: lineCode,
              lines: lines,
              isLast: time == times.last,
              until: time == departures.nextTime ? departures.untilNext : null,
            ),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String time;
  final _CellState state;
  final String lineCode;
  final List<String> lines;
  final Duration? until;
  final bool isLast;

  const _TimeCell({
    required this.time,
    required this.state,
    required this.lineCode,
    required this.lines,
    required this.until,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final line = lineColors(colorScheme, lines, lineCode);

    final (background, foreground, weight, border) = switch (state) {
      _CellState.next => (line.fill, line.text, FontWeight.w900, null),
      _CellState.past => (
        null,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        FontWeight.w800,
        null,
      ),
      _CellState.last => (
        colorScheme.surface,
        colorScheme.onSurface,
        FontWeight.w800,
        Border.all(color: colorScheme.onSurface),
      ),
      _CellState.normal => (
        colorScheme.surfaceContainer,
        colorScheme.onSurface,
        FontWeight.w800,
        null,
      ),
    };

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                time,
                style: TextStyle(
                  color: foreground,
                  fontSize: 17,
                  fontWeight: weight,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          if (state == _CellState.next && until != null)
            Text(
              countdownText(until!),
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (isLast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.onSurface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'SON',
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 9,
                  letterSpacing: 9 * 0.06,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sefer saati girilmemiş.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
