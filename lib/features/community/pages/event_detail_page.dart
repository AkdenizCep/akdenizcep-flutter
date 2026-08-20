import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/event_detail_view.dart';
import '../../../shared/models/feed_event.dart';
import 'components/club_summary_card.dart';

class EventDetailPage extends ConsumerWidget {
  final String clubId;
  final String eventId;

  const EventDetailPage({
    super.key,
    required this.clubId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EventDetailView(
      eventRef: EventRef.club(clubId: clubId, eventId: eventId),
      clubCard: ClubSummaryCard(
        clubId: clubId,
        onTap: () => context.push('/club/$clubId'),
      ),
    );
  }
}
