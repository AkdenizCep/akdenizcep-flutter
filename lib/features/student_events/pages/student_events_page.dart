import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../providers/student_events_provider.dart';

class StudentEventsPage extends ConsumerWidget {
  const StudentEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(studentEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ogrenci Etkinlikleri')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/student-events/create'),
        child: const Icon(Icons.add),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Henuz etkinlik yok.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.location} - ${DateFormat('dd.MM.yyyy').format(event.date)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.go('/student-events/${event.id}'),
                ),
              );
            },
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }
}
