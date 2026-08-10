import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/progress_snackbar.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/utils/error_message.dart';
import '../../providers/community_provider.dart';

/// Etkinlik detayındaki (1d) kulüp kartı — logo, isim, istatistik ve takip.
class ClubSummaryCard extends ConsumerWidget {
  final String clubId;
  final VoidCallback? onTap;

  const ClubSummaryCard({super.key, required this.clubId, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final club = ref.watch(clubDetailProvider(clubId)).valueOrNull;
    if (club == null) return const SizedBox.shrink();

    final events = ref.watch(clubEventsProvider(clubId)).valueOrNull ?? const [];
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isFollowing = currentUser?.followedClubs.contains(clubId) ?? false;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              _ClubLogo(logoUrl: club.logoUrl),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      '${club.followerCount} takipçi · '
                      '${events.length} etkinlik',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FollowButton(
                clubId: clubId,
                isFollowing: isFollowing,
                enabled: currentUser != null,
                height: 38,
                fontSize: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubLogo extends StatelessWidget {
  final String logoUrl;

  const _ClubLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: radius,
      ),
      child: Icon(
        Icons.groups_2_rounded,
        size: 26,
        color: colorScheme.primary,
      ),
    );
  }
}

/// Takip Et / Takipte butonu — 1d ve 1e ekranlarında ortak.
class FollowButton extends ConsumerStatefulWidget {
  final String clubId;
  final bool isFollowing;
  final bool enabled;
  final double height;
  final double fontSize;
  final bool expand;

  const FollowButton({
    super.key,
    required this.clubId,
    required this.isFollowing,
    required this.enabled,
    this.height = 46,
    this.fontSize = 14,
    this.expand = false,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final service = ref.read(communityServiceProvider);
      if (widget.isFollowing) {
        await service.unfollowClub(user.id, widget.clubId);
      } else {
        await service.followClub(user.id, widget.clubId);
      }
    } catch (e) {
      if (mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(widget.height / 2);
    final following = widget.isFollowing;

    final button = Material(
      color: following ? colorScheme.primaryContainer : colorScheme.primary,
      borderRadius: radius,
      child: InkWell(
        onTap: widget.enabled && !_busy ? _toggle : null,
        borderRadius: radius,
        child: Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.expand ? 12 : 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: following
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Text(
            following ? 'Takipte' : 'Takip Et',
            style: textTheme.labelLarge?.copyWith(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              color: following
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );

    return widget.expand ? Expanded(child: button) : button;
  }
}
