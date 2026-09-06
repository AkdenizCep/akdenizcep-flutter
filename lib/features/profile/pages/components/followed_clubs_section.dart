import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/components/error_view.dart';
import '../../../../shared/components/user_avatar.dart';
import '../../models/profile_club_summary.dart';
import '../../providers/profile_provider.dart';

class FollowedClubsSection extends ConsumerWidget {
  final bool preview;
  const FollowedClubsSection({super.key, this.preview = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(followedClubsProvider)
      .when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return Text(
              'Henüz topluluk takip etmiyorsun.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }
          if (!preview) {
            return Column(
              children: [
                for (final club in clubs)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: UserAvatar(
                      name: club.name,
                      imageUrl: club.logoUrl,
                      diameter: 52,
                    ),
                    title: Text(club.name),
                    subtitle: Text(club.category),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/club/${club.id}'),
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final club in clubs.take(4))
                Expanded(child: _ClubPreview(club: club)),
              for (var i = clubs.length; i < 4; i++) const Spacer(),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => ErrorView(
          message: 'Topluluklar yüklenemedi.',
          onRetry: () => ref.invalidate(followedClubsProvider),
        ),
      );
}

class _ClubPreview extends StatelessWidget {
  final ProfileClubSummary club;
  const _ClubPreview({required this.club});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => context.push('/club/${club.id}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Column(
        children: [
          UserAvatar(name: club.name, imageUrl: club.logoUrl, diameter: 60),
          const SizedBox(height: 9),
          Text(
            club.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
