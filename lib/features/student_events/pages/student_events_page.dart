import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/models/feed_event.dart';
import '../../../shared/providers/event_feed_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/event_category.dart';
import 'components/category_strip.dart';
import 'components/event_feed_card.dart';
import 'components/feed_header.dart';
import 'components/source_filter_row.dart';

/// Ekran 2a — kulüp ve öğrenci etkinliklerinin tek akışı.
class StudentEventsPage extends ConsumerWidget {
  const StudentEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(filteredFeedProvider);
    final selectedCategory = EventCategory.stripItems.firstWhere(
      (item) => item.id == ref.watch(selectedCategoryProvider),
      orElse: () => EventCategory.all,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: feed.when(
          data: (events) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FeedHeader(
                  onCreate: () => context.go('/student-events/create'),
                ),
              ),
              const SliverToBoxAdapter(child: CategoryStrip()),
              const SliverToBoxAdapter(child: SourceFilterRow()),
              SliverToBoxAdapter(
                child: _ResultRow(
                  categoryLabel: selectedCategory.id == EventCategory.all.id
                      ? 'Tüm kategoriler'
                      : selectedCategory.label,
                  count: events.length,
                ),
              ),
              if (events.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyEventsView(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  sliver: SliverList.separated(
                    itemCount: events.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventFeedCard(
                        event: event,
                        onTap: () => context.push(_detailRoute(event.ref)),
                        onAuthorTap: event.isClubEvent
                            ? () => context.push('/club/${event.clubId}')
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: errorMessage(e)),
        ),
      ),
    );
  }

  String _detailRoute(EventRef ref) => ref.clubId != null
      ? '/club/${ref.clubId}/event/${ref.eventId}'
      : '/event/${ref.eventId}';
}

class _ResultRow extends StatelessWidget {
  final String categoryLabel;
  final int count;

  const _ResultRow({required this.categoryLabel, required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count etkinlik',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
