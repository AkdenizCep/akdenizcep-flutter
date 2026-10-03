import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/app_top_bar.dart';
import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../models/turkish_text.dart';
import '../providers/ring_provider.dart';
import 'components/favorite_stops_sheet.dart';
import 'components/nearby_stops_row.dart';
import 'components/next_departure_card.dart';
import 'components/open_stop_detail.dart';
import 'components/ring_actions_row.dart';
import 'components/ring_empty_state.dart';
import 'components/ring_format.dart';
import 'components/ring_search_bar.dart';
import 'components/stop_list_tile.dart';

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
            final lines = ref.watch(availableLinesProvider);
            if (schedules.isEmpty || lines.isEmpty) {
              return const RingEmptyState();
            }
            return const _RingContent();
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(
            message: errorMessage(e),
            onRetry: () => ref.invalidate(ringSchedulesProvider),
          ),
        ),
      ),
    );
  }
}

/// Arama sorgusu yalnızca bu sayfayı ilgilendirdiği için global provider yerine
/// yerel state'te tutulur.
class _RingContent extends ConsumerStatefulWidget {
  const _RingContent();

  @override
  ConsumerState<_RingContent> createState() => _RingContentState();
}

class _RingContentState extends ConsumerState<_RingContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(lineDeparturesProvider);
    final isReturn = ref.watch(effectiveReturnDirectionProvider);
    final activeShape = ref.watch(activeScheduleRouteShapeProvider(isReturn));

    final canSwitchDirection = ref.watch(canSwitchDirectionProvider);

    final userAsync = ref.watch(currentUserProvider);
    final userInitial = userAsync.valueOrNull?.name.isNotEmpty == true
        ? userAsync.valueOrNull!.name[0].toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 130 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Üst başlık
          AppTopBar(
            title: 'Ulaşım',
            actions: [
              AppTopBarAction.avatar(
                initial: userInitial,
                imageUrl: userAsync.valueOrNull?.photoUrl,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 2. Hero kart — yön ve her hattın kaydırılabilir saat şeridi
                NextDepartureCard(
                  lines: lines,
                  originName: routeOrigin(activeShape),
                  destinationName: routeDestination(activeShape),
                  fallbackTitle: directionLabel(isReturn),
                  canSwitchDirection: canSwitchDirection,
                  onSwitchDirection: () =>
                      ref.read(isReturnDirectionProvider.notifier).state =
                          !isReturn,
                ),

                const SizedBox(height: 12),

                // 3. Arama satırı + favori durakları butonu
                Row(
                  children: [
                    Expanded(
                      child: RingSearchBar(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FavoriteStopsButton(
                      onTap: () => openFavoriteStopsSheet(context, ref),
                    ),
                  ],
                ),

                // 4. Arama sonuçları
                if (_query.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SearchResults(query: _query),
                ],
              ],
            ),
          ),

          // 5. Yakındaki duraklar (arama sırasında gizli). Kendi yatay
          // dolgusunu uyguladığı için yukarıdaki Padding'in dışında durur.
          if (_query.trim().isEmpty) ...[
            const SizedBox(height: 12),
            const NearbyStopsRow(),
          ],

          // 6. Haritada Gör + Tüm Tarife
          const RingActionsRow(),
        ],
      ),
    );
  }
}

class _FavoriteStopsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FavoriteStopsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Tooltip(
            message: 'Favori duraklar',
            child: Icon(
              Icons.star_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Arama kutusuna yazıldığında yakındaki duraklar şeridinin yerini alır.
class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = normalizeForSearch(query);

    final matches = ref
        .watch(nearbyStopsProvider)
        .where((n) => normalizeForSearch(n.stop.name).contains(normalized))
        .take(8)
        .toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'Eşleşen durak yok.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < matches.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          StopListTile(
            nearby: matches[i],
            onTap: () => openStopDetail(context, ref, matches[i].stop.id),
          ),
        ],
      ],
    );
  }
}
