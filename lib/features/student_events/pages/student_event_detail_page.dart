import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/event_detail_view.dart';
import '../../../shared/models/feed_event.dart';
import '../../../shared/providers/event_feed_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../providers/student_events_provider.dart';

class StudentEventDetailPage extends ConsumerWidget {
  final String eventId;

  const StudentEventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventRef = EventRef.student(eventId);
    final event = ref.watch(eventDetailProvider(eventRef)).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAuthor =
        currentUser != null && event != null && event.authorUid == currentUser.id;

    return EventDetailView(
      eventRef: eventRef,
      onDelete: isAuthor
          ? () async {
              await ref
                  .read(studentEventsServiceProvider)
                  .deleteEvent(eventId: eventId, authorUid: currentUser.id);
              if (context.mounted) context.pop();
            }
          : null,
    );
  }
}
