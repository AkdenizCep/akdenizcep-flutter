import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../providers/ring_provider.dart';

class RingPage extends ConsumerWidget {
  const RingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(ringSchedulesProvider);
    final isWeekend =
        DateTime.now().weekday == DateTime.saturday ||
        DateTime.now().weekday == DateTime.sunday;

    return Scaffold(
      appBar: AppBar(title: const Text('Ring Saatleri')),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(
                child: Text('Ring tarifesi bulunamadi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final times =
                  isWeekend ? schedule.weekend : schedule.weekday;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.lineId.replaceAll('_', ' ').toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWeekend ? 'Hafta Sonu' : 'Hafta Ici',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: times
                            .map((t) => Chip(label: Text(t)))
                            .toList(),
                      ),
                    ],
                  ),
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
