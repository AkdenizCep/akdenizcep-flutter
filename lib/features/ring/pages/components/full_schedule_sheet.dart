import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ring_departures.dart';
import '../../providers/ring_provider.dart';
import 'ring_format.dart';
import 'soft_segment.dart';

/// Secili hattin gun tarifesinin tamami. Gecmis saatler soluk, siradaki
/// kalkis vurgulu; acilista "simdi"ye kaydirilir.
///
/// Gun tipi anahtari sayfayla ayni provider'i kullanir — sheet kapandiginda
/// secim korunur.
class FullScheduleSheet extends ConsumerStatefulWidget {
  const FullScheduleSheet({super.key});

  @override
  ConsumerState<FullScheduleSheet> createState() => _FullScheduleSheetState();
}

class _FullScheduleSheetState extends ConsumerState<FullScheduleSheet> {
  /// Siradaki kalkis cipine baglanir; acilista oraya kaydirmak icin.
  final _nextTimeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    final context = _nextTimeKey.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      alignment: 0.35,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final schedule = ref.watch(selectedScheduleProvider);
    final isReturn = ref.watch(isReturnDirectionProvider);
    final activeShape = ref.watch(activeRouteShapeProvider(isReturn));
    final showWeekend = ref.watch(showWeekendProvider);
    final departures = ref.watch(departuresProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, sheetScrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule == null
                              ? 'Tüm Saatler'
                              : '${lineLabel(schedule.lineCode)} · '
                                    '${directionSummary(activeShape, isReturn: isReturn)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayTypeLabel(showWeekend),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 168,
                    child: SoftSegment<bool>(
                      compact: true,
                      selectedValue: showWeekend,
                      onChanged: (value) {
                        ref.read(showWeekendProvider.notifier).state = value;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToNow(),
                        );
                      },
                      items: const [
                        SegmentItem(value: false, label: 'H.İçi'),
                        SegmentItem(value: true, label: 'H.Sonu'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              // Kaydirma denetleyicisi her durumda bagli kalmali, aksi halde
              // sheet suruklenerek kapatilamaz.
              child: SingleChildScrollView(
                controller: sheetScrollController,
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: departures.times.isEmpty
                    ? _EmptySchedule(showWeekend: showWeekend)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final time in departures.times)
                                _TimeChip(
                                  key: time == departures.nextTime
                                      ? _nextTimeKey
                                      : null,
                                  time: time,
                                  state: _stateFor(time, departures),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _FooterNote(isToday: departures.isToday),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  _TimeState _stateFor(String time, RingDepartures departures) {
    if (!departures.isToday) return _TimeState.neutral;
    if (time == departures.nextTime) return _TimeState.next;

    final next = departures.nextTime;
    // Siradaki kalkis yoksa gunun tamami gecmistir.
    if (next == null) return _TimeState.past;
    return time.compareTo(next) < 0 ? _TimeState.past : _TimeState.neutral;
  }
}

enum _TimeState { past, next, neutral }

class _TimeChip extends StatelessWidget {
  final String time;
  final _TimeState state;

  const _TimeChip({super.key, required this.time, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (background, foreground, border) = switch (state) {
      _TimeState.next => (
        colorScheme.primary,
        colorScheme.onPrimary,
        colorScheme.primary,
      ),
      _TimeState.past => (
        Colors.transparent,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      _TimeState.neutral => (
        colorScheme.surface,
        colorScheme.onSurface,
        colorScheme.outlineVariant,
      ),
    };

    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: foreground,
          fontSize: 15,
          fontWeight: state == _TimeState.next
              ? FontWeight.w900
              : FontWeight.w700,
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  final bool isToday;

  const _FooterNote({required this.isToday});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isToday
                ? 'Saatler hattın kalkış noktasına aittir.'
                : 'Başka bir gün tipinin tarifesini görüyorsun.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final bool showWeekend;

  const _EmptySchedule({required this.showWeekend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        '${dayTypeLabel(showWeekend)} için sefer saati girilmemiş.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
