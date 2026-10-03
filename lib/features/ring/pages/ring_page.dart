import 'dart:math';

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
  /// Sayfanın yatay kenar boşluğu.
  static const _pageEdge = 20.0;

  /// Bloklar arasındaki asgari dikey boşluk (küçük ekranda geçerli olan).
  static const _minGap = 12.0;

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

    final isSearching = _query.trim().isNotEmpty;
    final hasNearbyStops = ref.watch(
      nearbyStopsProvider.select((stops) => stops.isNotEmpty),
    );
    // [HomePage] `extendBody: true` kullanır; Scaffold yüzen nav bar'ın
    // yüksekliğini (sistem çubuğu dahil) body'nin `padding.bottom` değerine
    // ekler. İçerik bunun altına kaymasın diye kaydırma alanının altında
    // yalnızca bu kadar boşluk bırakılır; üstüne ayrıca sabit pay eklenirse
    // içerik sığsa bile sayfa kayar ve alt boşluk gereğinden büyük kalır.
    final navInset = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Nav bar'ın üstünde kalan görünür alan. İçerik bundan kısaysa Column
        // bu yüksekliğe kadar uzar ve artan boşluğu eşit paylaştırır; uzunsa
        // sayfa her zamanki gibi kayar. Arama sırasında sonuçlar yukarıdan
        // akar, boşluk dağıtılmaz.
        final minContentHeight = isSearching
            ? 0.0
            : max(0.0, constraints.maxHeight - navInset);

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: navInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Çocuklar arasındaki serbest alan eşit bölünür: üst bar sabit
              // üstte, sondaki boş çocuk son bloğun altına aynı payı bırakır.
              // Her bloğun kendi üst dolgusu, küçük ekrandaki asgari boşluktur.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                // 2. Hero kart — yön ve her hattın kaydırılabilir saat şeridi
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _pageEdge,
                    4,
                    _pageEdge,
                    0,
                  ),
                  child: NextDepartureCard(
                    lines: lines,
                    originName: routeOrigin(activeShape),
                    destinationName: routeDestination(activeShape),
                    fallbackTitle: directionLabel(isReturn),
                    canSwitchDirection: canSwitchDirection,
                    onSwitchDirection: () =>
                        ref.read(isReturnDirectionProvider.notifier).state =
                            !isReturn,
                  ),
                ),

                // 3. Arama satırı + favori durakları butonu, ardından sonuçlar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _pageEdge,
                    _minGap,
                    _pageEdge,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RingSearchBar(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FavoriteStopsButton(
                            onTap: () => openFavoriteStopsSheet(context, ref),
                          ),
                        ],
                      ),
                      if (isSearching) ...[
                        const SizedBox(height: 22),
                        _SearchResults(query: _query),
                      ],
                    ],
                  ),
                ),

                // 4. Yakındaki duraklar (arama sırasında gizli). Kendi yatay
                // dolgusunu uyguladığı için sayfa kenarı dolgusunun dışında
                // durur. Veri yoksa boş bir slot olarak değil, hiç eklenmez;
                // aksi halde o slot fazladan bir boşluk payı alırdı.
                if (!isSearching && hasNearbyStops)
                  const Padding(
                    padding: EdgeInsets.only(top: _minGap),
                    child: NearbyStopsRow(),
                  ),

                // 5. Haritada Gör + Tüm Tarife (üst dolgusunu kendisi verir)
                const RingActionsRow(),

                // Son bloğun altındaki boşluk payı için boş slot.
                const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
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
