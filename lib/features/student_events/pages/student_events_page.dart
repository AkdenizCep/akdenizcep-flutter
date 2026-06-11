import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../models/student_event.dart';
import '../providers/student_events_provider.dart';
import 'components/student_event_card.dart';

enum _EventFeedFilter { all, today, upcoming, past }

class StudentEventsPage extends ConsumerStatefulWidget {
  const StudentEventsPage({super.key});

  @override
  ConsumerState<StudentEventsPage> createState() => _StudentEventsPageState();
}

class _StudentEventsPageState extends ConsumerState<StudentEventsPage> {
  final _searchController = TextEditingController();
  _EventFeedFilter _selectedFilter = _EventFeedFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(studentEventsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: eventsAsync.when(
          data: (events) {
            final visibleEvents = _filterEvents(events);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _FeedHeader(
                    searchController: _searchController,
                    selectedFilter: _selectedFilter,
                    onSearchChanged: (_) => setState(() {}),
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                ),
                if (visibleEvents.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyEventsView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: visibleEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = visibleEvents[index];
                        return StudentEventCard(
                          event: event,
                          onTap: () =>
                              context.go('/student-events/${event.id}'),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: e.toString()),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          onPressed: () => context.go('/student-events/create'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<StudentEvent> _filterEvents(List<StudentEvent> events) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return events.where((event) {
      final matchesSearch =
          query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      final eventDay = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      switch (_selectedFilter) {
        case _EventFeedFilter.all:
          return true;
        case _EventFeedFilter.today:
          return eventDay == today;
        case _EventFeedFilter.upcoming:
          return !eventDay.isBefore(today);
        case _EventFeedFilter.past:
          return eventDay.isBefore(today);
      }
    }).toList();
  }
}

class _FeedHeader extends StatelessWidget {
  final TextEditingController searchController;
  final _EventFeedFilter selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_EventFeedFilter> onFilterChanged;

  const _FeedHeader({
    required this.searchController,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.groups_2_rounded,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akdeniz Cep',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ETKİNLİK AKIŞI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bildirimler',
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  shape: const CircleBorder(),
                ),
                icon: Badge(
                  smallSize: 8,
                  backgroundColor: colorScheme.error,
                  child: Icon(
                    Icons.notifications_rounded,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Kulüp veya etkinlik ara...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
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
          ),
        ),
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _EventFilterChip(
                label: 'Hepsi',
                icon: Icons.apps_rounded,
                selected: selectedFilter == _EventFeedFilter.all,
                onSelected: () => onFilterChanged(_EventFeedFilter.all),
              ),
              _EventFilterChip(
                label: 'Bugün',
                icon: Icons.today_rounded,
                selected: selectedFilter == _EventFeedFilter.today,
                onSelected: () => onFilterChanged(_EventFeedFilter.today),
              ),
              _EventFilterChip(
                label: 'Yakında',
                icon: Icons.event_available_rounded,
                selected: selectedFilter == _EventFeedFilter.upcoming,
                onSelected: () => onFilterChanged(_EventFeedFilter.upcoming),
              ),
              _EventFilterChip(
                label: 'Geçmiş',
                icon: Icons.history_rounded,
                selected: selectedFilter == _EventFeedFilter.past,
                onSelected: () => onFilterChanged(_EventFeedFilter.past),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _EventFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        showCheckmark: false,
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}

class _EmptyEventsView extends StatelessWidget {
  const _EmptyEventsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.event_busy_rounded,
              color: colorScheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz etkinlik yok.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Aramanı veya filtrelerini değiştirerek tekrar deneyebilirsin.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
