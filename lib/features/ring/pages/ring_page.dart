import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../models/ring_schedule.dart';
import '../providers/ring_provider.dart';

enum _RingView { schedule, map }

class RingPage extends ConsumerStatefulWidget {
  const RingPage({super.key});

  @override
  ConsumerState<RingPage> createState() => _RingPageState();
}

class _RingPageState extends ConsumerState<RingPage> {
  final _searchController = TextEditingController();
  _RingView _selectedView = _RingView.schedule;
  int _selectedLineIndex = 0;
  bool _isDonus = false;
  late bool _showWeekend;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _showWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(ringSchedulesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: schedulesAsync.when(
          data: (schedules) {
            if (schedules.isEmpty) {
              return const _RingEmptyState();
            }

            final selectedSchedule = _findSchedule(schedules);
            if (selectedSchedule == null) {
              return const _RingEmptyState();
            }
            final filteredSchedules = _filterSchedules(schedules);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RingHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                        child: _ScheduleMapSegment(
                          selectedView: _selectedView,
                          onChanged: (view) {
                            setState(() => _selectedView = view);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _LineSelector(
                                selectedIndex: _selectedLineIndex,
                                onChanged: (index) {
                                  setState(() => _selectedLineIndex = index);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            _DirectionToggle(
                              isDonus: _isDonus,
                              onChanged: (value) {
                                setState(() => _isDonus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _DayToggle(
                              showWeekend: _showWeekend,
                              onChanged: (value) {
                                  setState(() => _showWeekend = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedView == _RingView.schedule)
                  ..._buildScheduleView(
                    context,
                    selectedSchedule,
                    filteredSchedules,
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MapPlaceholder(schedule: selectedSchedule),
                  ),
              ],
            );
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: e.toString()),
        ),
      ),
    );
  }

  List<Widget> _buildScheduleView(
    BuildContext context,
    RingSchedule selectedSchedule,
    List<RingSchedule> filteredSchedules,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
          child: _LiveRingCard(
            schedule: selectedSchedule,
            showWeekend: _showWeekend,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 0),
          child: _SearchField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 34, 22, 0),
          child: Text(
            'YAKINDAKİ DURAKLAR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      if (filteredSchedules.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _NoSearchResult(),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
          sliver: SliverList.separated(
            itemCount: filteredSchedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 22),
            itemBuilder: (context, index) {
              return _StopScheduleCard(
                schedule: filteredSchedules[index],
                showWeekend: _showWeekend,
              );
            },
          ),
        ),
    ];
  }

  List<RingSchedule> _filterSchedules(List<RingSchedule> schedules) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return schedules;

    return schedules.where((schedule) {
      final meta = _RingLineMeta.fromSchedule(schedule);
      return meta.lineLabel.toLowerCase().contains(query) ||
          meta.stopName.toLowerCase().contains(query) ||
          meta.routeLabel.toLowerCase().contains(query) ||
          schedule.lineId.toLowerCase().contains(query);
    }).toList();
  }

  RingSchedule? _findSchedule(List<RingSchedule> schedules) {
    final lineNumbers = ['102', '103'];
    final targetLine = lineNumbers[_selectedLineIndex.clamp(0, 1)];
    final direction = _isDonus ? 'donus' : 'gidis';

    for (final schedule in schedules) {
      final normalized = schedule.lineId.toLowerCase();
      if (normalized.contains(targetLine) && normalized.contains(direction)) {
        return schedule;
      }
    }
    return null;
  }
}

class _RingHeader extends StatelessWidget {
  const _RingHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school,
              color: colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akdeniz Cep',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kampüs Rehberi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

class _ScheduleMapSegment extends StatelessWidget {
  final _RingView selectedView;
  final ValueChanged<_RingView> onChanged;

  const _ScheduleMapSegment({
    required this.selectedView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftSegment<_RingView>(
      items: const [
        _SegmentItem(value: _RingView.schedule, label: 'Tarife'),
        _SegmentItem(value: _RingView.map, label: 'Harita'),
      ],
      selectedValue: selectedView,
      onChanged: onChanged,
    );
  }
}

class _LineSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _LineSelector({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftSegment<int>(
      items: const [
        _SegmentItem(value: 0, label: 'AÜ102'),
        _SegmentItem(value: 1, label: 'AÜ103'),
      ],
      selectedValue: selectedIndex.clamp(0, 1),
      onChanged: (index) => onChanged(index.clamp(0, 1)),
      compact: true,
    );
  }
}

class _DayToggle extends StatelessWidget {
  final bool showWeekend;
  final ValueChanged<bool> onChanged;

  const _DayToggle({
    required this.showWeekend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isWeekend = showWeekend;
    final bgColor = isWeekend
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);
    final textColor = isWeekend
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () => onChanged(!showWeekend),
      child: Container(
        width: 92,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              isWeekend ? 'H.Sonu' : 'H.İçi',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final bool isDonus;
  final ValueChanged<bool> onChanged;

  const _DirectionToggle({
    required this.isDonus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDonus
        ? const Color(0xFFE0F2F1)
        : const Color(0xFFE3F2FD);
    final textColor = isDonus
        ? const Color(0xFF00695C)
        : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => onChanged(!isDonus),
      child: Container(
        width: 80,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              isDonus ? 'Dönüş' : 'Gidiş',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftSegment<T> extends StatelessWidget {
  final List<_SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final bool compact;

  const _SoftSegment({
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

class _SegmentItem<T> {
  final T value;
  final String label;

  const _SegmentItem({
    required this.value,
    required this.label,
  });
}

class _LiveRingCard extends StatelessWidget {
  final RingSchedule schedule;
  final bool showWeekend;

  const _LiveRingCard({
    required this.schedule,
    required this.showWeekend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _RingLineMeta.fromSchedule(schedule);
    final times = _timesFor(schedule, showWeekend);
    final next = _nextDeparture(times);
    final waitText = _waitText(next);
    final departureText = next ?? (times.isNotEmpty ? times.first : '--:--');

    return Container(
      height: 217,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
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
              Icons.directions_bus_filled,
              size: 142,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meta.lineLabel} · EN YAKIN KALKIŞ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      departureText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          meta.routeLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Colors.white.withValues(alpha: 0.86),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        waitText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Durak veya ring ara...',
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _StopScheduleCard extends StatelessWidget {
  final RingSchedule schedule;
  final bool showWeekend;

  const _StopScheduleCard({
    required this.schedule,
    required this.showWeekend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final meta = _RingLineMeta.fromSchedule(schedule);
    final times = _timesFor(schedule, showWeekend);
    final next = _nextDeparture(times);
    final wait = _waitMinutes(next);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.departure_board,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LineBadge(label: meta.lineLabel),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            meta.stopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.routeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VARIŞ SÜRESİ',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wait == null ? '-- dk' : '$wait dk',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bir Sonraki Ring:',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                next ?? (times.isNotEmpty ? times.first : '--:--'),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                elevation: 0,
                foregroundColor: colorScheme.primary,
                backgroundColor:
                    colorScheme.primaryContainer.withValues(alpha: 0.30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                _showFullSchedule(context, schedule, showWeekend);
              },
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text(
                'Tam Tarife',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullSchedule(
    BuildContext context,
    RingSchedule schedule,
    bool showWeekend,
  ) {
    final meta = _RingLineMeta.fromSchedule(schedule);
    final times = _timesFor(schedule, showWeekend);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meta.lineLabel} Tam Tarife',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(showWeekend ? 'Hafta Sonu' : 'Hafta İçi'),
                const SizedBox(height: 18),
                if (times.isEmpty)
                  const Text('Bu gün için sefer saati bulunamadı.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final time in times)
                        Chip(
                          label: Text(time),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LineBadge extends StatelessWidget {
  final String label;

  const _LineBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final RingSchedule schedule;

  const _MapPlaceholder({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _RingLineMeta.fromSchedule(schedule);

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                color: colorScheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${meta.lineLabel} haritası',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ring güzergahı koordinatları eklendiğinde bu alanda canlı harita gösterilecek.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingEmptyState extends StatelessWidget {
  const _RingEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Ring tarifesi bulunamadı.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Aramana uygun ring bulunamadı.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _RingLineMeta {
  final String lineLabel;
  final String stopName;
  final String routeLabel;

  const _RingLineMeta({
    required this.lineLabel,
    required this.stopName,
    required this.routeLabel,
  });

  factory _RingLineMeta.fromSchedule(RingSchedule schedule) {
    final normalized = schedule.lineId.toLowerCase();
    final isDonus = normalized.contains('donus');
    final is103 = normalized.contains('103');
    final is102 = normalized.contains('102');

    if (is103) {
      return _RingLineMeta(
        lineLabel: isDonus ? 'AÜ103 (Dönüş)' : 'AÜ103 (Gidiş)',
        stopName: isDonus ? 'Üniversite Evi' : 'KYK Yurtları',
        routeLabel: isDonus ? 'KYK Yönü · Mavi Ring' : 'Çarşı Yönü · Mavi Ring',
      );
    }

    if (is102) {
      return _RingLineMeta(
        lineLabel: isDonus ? 'AÜ102 (Dönüş)' : 'AÜ102 (Gidiş)',
        stopName: isDonus ? 'Rektörlük' : 'Meltem Kapısı',
        routeLabel: isDonus ? 'Meltem Yönü · Kuzey Ring' : 'Rektörlük Yönü · Kuzey Ring',
      );
    }

    final fallbackLabel = schedule.lineId.replaceAll('_', ' ').toUpperCase();
    return _RingLineMeta(
      lineLabel: fallbackLabel,
      stopName: fallbackLabel,
      routeLabel: showRouteLabel(fallbackLabel),
    );
  }

  static String showRouteLabel(String label) => '$label · Ring Hattı';
}

List<String> _timesFor(RingSchedule schedule, bool showWeekend) {
  final times = showWeekend ? schedule.weekend : schedule.weekday;
  return [...times]..sort();
}

String? _nextDeparture(List<String> times) {
  final now = DateTime.now();

  for (final time in times) {
    final departure = _dateTimeForToday(time, now);
    if (departure != null && !departure.isBefore(now)) {
      return time;
    }
  }

  return null;
}

int? _waitMinutes(String? time) {
  if (time == null) return null;

  final now = DateTime.now();
  final departure = _dateTimeForToday(time, now);
  if (departure == null) return null;

  final minutes = departure.difference(now).inMinutes;
  return minutes < 0 ? null : minutes;
}

String _waitText(String? time) {
  final minutes = _waitMinutes(time);
  if (minutes == null) return 'Bugün için başka kalkış görünmüyor';
  if (minutes == 0) return 'Peron 1’den kalkış anons edildi';
  return 'Peron 1’den kalkışa $minutes dakika kaldı';
}

DateTime? _dateTimeForToday(String time, DateTime now) {
  final parts = time.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return DateTime(now.year, now.month, now.day, hour, minute);
}
