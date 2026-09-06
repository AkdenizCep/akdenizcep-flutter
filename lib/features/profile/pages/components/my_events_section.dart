import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/components/error_view.dart';
import '../../../../shared/providers/event_feed_provider.dart';
import '../../models/profile_event_summary.dart';
import '../../providers/profile_provider.dart';

class MyEventsSection extends ConsumerWidget {
  final bool joined;
  final int? limit;
  const MyEventsSection({super.key, this.joined = false, this.limit = 2});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = joined
        ? ref.watch(joinedEventsProvider)
        : ref.watch(myEventsProvider);
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Text(
            joined
                ? 'Henüz bir etkinliğe katılmadın.'
                : 'Henüz etkinlik oluşturmadın.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Column(
          children: [
            for (final event in limit == null ? events : events.take(limit!))
              ProfileEventTile(event: event),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => ErrorView(
        message: 'Etkinlikler yüklenemedi.',
        onRetry: () {
          if (joined) {
            ref.invalidate(eventFeedProvider);
          } else {
            ref.invalidate(myEventsProvider);
          }
        },
      ),
    );
  }
}

class ProfileEventTile extends StatelessWidget {
  final ProfileEventSummary event;
  const ProfileEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          event.clubId == null
              ? '/event/${event.id}'
              : '/club/${event.clubId}/event/${event.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('d', 'tr').format(event.date),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM',
                        'tr',
                      ).format(event.date).replaceAll('i', 'İ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('HH:mm', 'tr').format(event.date)} · ${event.location}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.outline,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
