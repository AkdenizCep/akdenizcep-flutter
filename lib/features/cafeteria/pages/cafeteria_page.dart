import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../providers/cafeteria_provider.dart';

class CafeteriaPage extends ConsumerWidget {
  const CafeteriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final ratingsAsync = ref.watch(ratingsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemekhane'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (date != null) {
                ref.read(selectedDateProvider.notifier).state = date;
              }
            },
          ),
        ],
      ),
      body: menuAsync.when(
        data: (menus) {
          if (menus.isEmpty) {
            return const Center(child: Text('Bugun icin menu bulunamadi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              final rating = ratingsAsync.valueOrNull?.where(
                (r) => r.mealName == menu.mealType,
              );
              final avgRating = rating?.isNotEmpty == true
                  ? rating!.first.avgRating
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            menu.mealType.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          if (avgRating != null)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(avgRating.toStringAsFixed(1)),
                              ],
                            ),
                        ],
                      ),
                      const Divider(),
                      ...menu.items.map((item) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Text('- $item'),
                          )),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(5, (i) {
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color: i < (avgRating?.round() ?? 0)
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            ),
                            onPressed: () async {
                              if (currentUser == null) return;
                              try {
                                await ref
                                    .read(cafeteriaServiceProvider)
                                    .rateMeal(
                                      uid: currentUser.id,
                                      date: DateFormat('yyyy-MM-dd')
                                          .format(selectedDate),
                                      mealName: menu.mealType,
                                      rating: i + 1,
                                    );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                          );
                        }),
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
