import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../providers/student_events_provider.dart';

class StudentEventDetailPage extends ConsumerWidget {
  final String eventId;

  const StudentEventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(studentEventDetailProvider(eventId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detay'),
        actions: [
          eventAsync.whenOrNull(
                data: (event) {
                  if (currentUser?.id != event.authorUid) return null;
                  return IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Etkinligi Sil'),
                          content: const Text(
                              'Bu etkinligi silmek istediginize emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Iptal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(studentEventsServiceProvider)
                            .deleteEvent(
                              eventId: eventId,
                              authorUid: currentUser!.id,
                            );
                        if (context.mounted) context.pop();
                      }
                    },
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr')
                      .format(event.date)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 8),
                  Text(event.location),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}
