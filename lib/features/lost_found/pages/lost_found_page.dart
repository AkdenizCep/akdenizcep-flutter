import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/relative_time.dart';
import '../models/lost_found_category.dart';
import '../models/lost_found_item.dart';
import '../providers/lost_found_provider.dart';
import 'components/lost_found_item_sheet.dart';

class LostFoundPage extends ConsumerWidget {
  const LostFoundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(lostFoundItemsProvider);
    final filtered = ref.watch(filteredLostFoundItemsProvider);
    final myListingsOnly = ref.watch(showMyListingsOnlyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıp & Buluntu')),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: itemsAsync.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return _EmptyState(myListingsOnly: myListingsOnly);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) => _LostFoundCard(
                    item: filtered[index],
                    onTap: () => LostFoundItemSheet.show(context, filtered[index]),
                  ),
                );
              },
              loading: () => const LoadingOverlay(),
              error: (e, _) => ErrorView(message: errorMessage(e)),
            ),
          ),
        ],
      ),
      // Uygulamanın yüzen alt navigasyon çubuğu ekranın en altına biniyor;
      // varsayılan FAB konumu onun arkasında kalıp görünmez olurdu (bkz.
      // student_events_page.dart'taki aynı çözüm). Çubuğa daha yakın dursun
      // diye boşluk 120'den 90'a indirildi.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/campus/lost-found/create'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('İlan Ver'),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(lostFoundTypeFilterProvider);
    final myListingsOnly = ref.watch(showMyListingsOnlyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Hepsi',
              selected: typeFilter == LostFoundTypeFilter.all,
              onTap: () => ref
                  .read(lostFoundTypeFilterProvider.notifier)
                  .state = LostFoundTypeFilter.all,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Kayıp',
              selected: typeFilter == LostFoundTypeFilter.lost,
              onTap: () => ref
                  .read(lostFoundTypeFilterProvider.notifier)
                  .state = LostFoundTypeFilter.lost,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Bulundu',
              selected: typeFilter == LostFoundTypeFilter.found,
              onTap: () => ref
                  .read(lostFoundTypeFilterProvider.notifier)
                  .state = LostFoundTypeFilter.found,
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 22, color: colorScheme.outlineVariant),
            const SizedBox(width: 14),
            _FilterChip(
              label: 'İlanlarım',
              selected: myListingsOnly,
              icon: Icons.person_outline_rounded,
              onTap: () => ref
                  .read(showMyListingsOnlyProvider.notifier)
                  .state = !myListingsOnly,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onTap;

  const _LostFoundCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final category = LostFoundCategory.resolve(item.category);
    final typeColor = item.isLost ? colorScheme.error : const Color(0xFF168A5B);

    return Opacity(
      opacity: item.isResolved ? 0.55 : 1,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.56),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(item: item, category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeBadge(isLost: item.isLost, color: typeColor),
                          if (item.isResolved) ...[
                            const SizedBox(width: 6),
                            Text(
                              'ÇÖZÜLDÜ',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(category.icon, size: 13, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${category.label} · ${item.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relativeTime(item.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final LostFoundItem item;
  final LostFoundCategory category;

  const _Thumbnail({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item.imageUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(category.icon, color: category.color, size: 26),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 64,
          height: 64,
          color: colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          width: 64,
          height: 64,
          color: colorScheme.surfaceContainerHighest,
          child: Icon(category.icon, color: colorScheme.onSurfaceVariant, size: 22),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isLost;
  final Color color;

  const _TypeBadge({required this.isLost, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      isLost ? 'KAYIP' : 'BULUNDU',
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool myListingsOnly;

  const _EmptyState({required this.myListingsOnly});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              myListingsOnly
                  ? 'Henüz bir ilan vermedin.'
                  : 'Bu filtrede ilan yok.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
