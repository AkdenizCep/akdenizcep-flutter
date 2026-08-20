import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_club_summary.dart';
import '../../providers/profile_provider.dart';

class FollowedClubsSection extends ConsumerWidget {
  const FollowedClubsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(followedClubsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return Text(
            'Henüz topluluk takip etmiyorsun.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < clubs.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ClubTile(club: clubs[i]),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ClubTile extends StatelessWidget {
  final ProfileClubSummary club;

  const _ClubTile({required this.club});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/club/${club.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: club.logoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(club.logoUrl)
                      : null,
                  child: club.logoUrl.isEmpty
                      ? Text(
                          club.name.isNotEmpty
                              ? club.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    club.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (club.category.isNotEmpty)
                  Chip(
                    label: Text(club.category),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
