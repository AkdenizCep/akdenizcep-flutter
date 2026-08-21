import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/event_detail_view.dart';
import '../../../shared/models/feed_event.dart';
import '../../../shared/providers/event_feed_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../providers/community_provider.dart';
import 'components/attendance_entry_card.dart';
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
    final eventRef = EventRef.club(clubId: clubId, eventId: eventId);
    final event = ref.watch(eventDetailProvider(eventRef)).valueOrNull;
    final club = ref.watch(clubDetailProvider(clubId)).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;

    final canScan =
        event?.qrAttendance == true &&
        club != null &&
        user != null &&
        club.isAdmin(user.id);

    return EventDetailView(
      eventRef: eventRef,
      clubCard: ClubSummaryCard(
        clubId: clubId,
        onTap: () => context.push('/club/$clubId'),
      ),
      attendanceCard: canScan
          ? AttendanceEntryCard(
              onTap: () => context.push('/club/$clubId/event/$eventId/scan'),
            )
          : null,
    );
  }
}
