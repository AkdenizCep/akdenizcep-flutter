import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../providers/ring_provider.dart';
import 'components/favorite_stops_row.dart';
import 'components/next_departure_card.dart';
import 'components/ring_empty_state.dart';
import 'components/ring_format.dart';
import 'components/ring_grid_actions.dart';
import 'components/ring_header.dart';
import 'components/ring_search_bar.dart';

/// Ring sayfası ana ekranı.
class RingPage extends ConsumerWidget {
  const RingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(ringSchedulesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: schedulesAsync.when(
          data: (schedules) {
            final activeLine = ref.watch(activeLineProvider);
            if (schedules.isEmpty || activeLine == null) {
              return const RingEmptyState();
            }
            return const _RingContent();
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: errorMessage(e)),
        ),
      ),
    );
  }
}

class _RingContent extends ConsumerWidget {
  const _RingContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLine = ref.watch(activeLineProvider);
    final availableLines = ref.watch(availableLinesProvider);
    final schedule = ref.watch(selectedScheduleProvider);
    final stopMap = ref.watch(ringStopMapProvider);
    final departures = ref.watch(departuresProvider);
    final isReturn = ref.watch(isReturnDirectionProvider);

    final canSwitchDirection = ref
        .watch(activeLineSchedulesProvider)
        .any((s) => s.isReturn != isReturn);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        130 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Üst Başlık (Header)
          const RingHeader(),

          const SizedBox(height: 18),

          // 2. Ana Mavi Hero Kart (Kalkış Zamanı / Hat Kartı)
          if (activeLine != null)
            NextDepartureCard(
              departures: departures,
              activeLine: activeLine,
              availableLines: availableLines,
              directionSummary: directionSummary(schedule, stopMap),
              canSwitchDirection: canSwitchDirection,
              onLineChanged: (line) =>
                  ref.read(selectedLineProvider.notifier).state = line,
              onSwitchDirection: () =>
                  ref.read(isReturnDirectionProvider.notifier).state = !isReturn,
            ),

          const SizedBox(height: 18),

          // 3. Arama Çubuğu
          const RingSearchBar(),

          const SizedBox(height: 24),

          // 4. Sık Kullanılan Duraklar
          const FavoriteStopsRow(),

          const SizedBox(height: 24),

          // 5. Alt Izgara Aksiyon Kartları ("Tüm Tarife" & "Yakındaki Duraklar")
          const RingGridActions(),
        ],
      ),
    );
  }
}
