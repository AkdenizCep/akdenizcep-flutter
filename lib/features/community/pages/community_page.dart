import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/event_category.dart';
import '../models/club.dart';
import '../providers/community_provider.dart';

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  static const _categories = [
    'Tümü',
    'Teknoloji',
    'Spor',
    'Sanat',
    'Müzik',
    'Akademik',
    'Sosyal',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(filteredClubsProvider);
    final selectedCategory = ref.watch(clubCategoryFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplulukları Keşfet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHigh
                    : const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(23),
              ),
              child: TextField(
                onChanged: (value) =>
                    ref.read(clubSearchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Topluluk veya kategori ara...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Categories horizontal strip
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => ref
                      .read(clubCategoryFilterProvider.notifier)
                      .state = cat,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : (isDark
                              ? colorScheme.surfaceContainerHigh
                              : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Club List
          Expanded(
            child: clubsAsync.when(
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 52,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Topluluk bulunamadı',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arama terimini veya filtreyi değiştirmeyi deneyin.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                  itemCount: clubs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return _ClubCard(club: club);
                  },
                );
              },
              loading: () => const LoadingOverlay(),
              error: (e, _) => ErrorView(message: errorMessage(e)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final Club club;

  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catInfo = EventCategory.resolve(club.category);

    return Material(
      color: isDark ? colorScheme.surface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/club/${club.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catInfo.color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: club.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: club.logoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _ClubInitial(club: club),
                        )
                      : _ClubInitial(club: club),
                ),
              ),

              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            club.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (club.verified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (club.description.isNotEmpty)
                      Text(
                        club.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: catInfo.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catInfo.icon,
                                size: 12,
                                color: catInfo.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                club.category,
                                style: TextStyle(
                                  color: catInfo.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Follower badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${club.followerCount} takipçi',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubInitial extends StatelessWidget {
  final Club club;

  const _ClubInitial({required this.club});

  @override
  Widget build(BuildContext context) {
    final initial = club.name.isNotEmpty ? club.name[0].toUpperCase() : '?';
    final catInfo = EventCategory.resolve(club.category);

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: catInfo.color,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

