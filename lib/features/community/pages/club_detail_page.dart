import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/event_visual.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/event_category.dart';
import '../models/club.dart';
import '../models/club_event.dart';
import '../providers/community_provider.dart';
import 'components/club_event_row.dart';
import 'components/club_summary_card.dart';

/// Ekran 1e — kulüp profili.
class ClubDetailPage extends ConsumerStatefulWidget {
  final String clubId;

  const ClubDetailPage({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends ConsumerState<ClubDetailPage> {
  bool _showEvents = true;

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubDetailProvider(widget.clubId));

    return Scaffold(
      body: clubAsync.when(
        data: _buildContent,
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }

  Widget _buildContent(Club club) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final events = ref.watch(clubEventsProvider(widget.clubId)).valueOrNull ??
        const <ClubEvent>[];
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isFollowing =
        currentUser?.followedClubs.contains(widget.clubId) ?? false;
    final isAdmin = currentUser != null && club.isAdmin(currentUser.id);

    final now = DateTime.now();
    final upcomingCount = events.where((e) => e.date.isAfter(now)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cover(club: club),
          Transform.translate(
            offset: const Offset(0, -38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ClubLogo(club: club),
                      ),
                      const SizedBox(width: 14),
                      FollowButton(
                        clubId: widget.clubId,
                        isFollowing: isFollowing,
                        enabled: currentUser != null,
                        expand: true,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 10),
                        _ManageButton(
                          onTap: () =>
                              context.push('/club/${widget.clubId}/settings'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          club.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (club.verified) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (club.category.isNotEmpty)
                        _Tag(
                          label: club.category,
                          background: colorScheme.primaryContainer,
                          foreground: colorScheme.onPrimaryContainer,
                        ),
                    ],
                  ),
                  if (club.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      club.description,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${club.followerCount}',
                          label: 'TAKİPÇİ',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${events.length}',
                          label: 'ETKİNLİK',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$upcomingCount',
                          label: 'YAKLAŞAN',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Tabs(
                    showEvents: _showEvents,
                    onChanged: (value) => setState(() => _showEvents = value),
                  ),
                  const SizedBox(height: 16),
                  if (_showEvents)
                    _EventsTab(clubId: widget.clubId, events: events)
                  else
                    _AboutTab(club: club),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final Club club;

  const _Cover({required this.club});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventVisual(
            imageUrl: club.coverUrl,
            category: EventCategory.resolve(
              club.category,
              fallbackText: club.name,
            ),
            watermarkSize: 150,
            scrimHeight: 0,
          ),
          Positioned(
            top: topInset + 8,
            left: 20,
            child: Material(
              color: Colors.black.withValues(alpha: 0.32),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubLogo extends StatelessWidget {
  final Club club;

  const _ClubLogo({required this.club});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = EventCategory.resolve(
      club.category,
      fallbackText: club.name,
    );

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: club.logoUrl.isNotEmpty
          ? CachedNetworkImage(imageUrl: club.logoUrl, fit: BoxFit.cover)
          : ColoredBox(
              color: category.color.withValues(alpha: 0.14),
              child: Icon(category.icon, size: 40, color: category.color),
            ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(23));

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Yönet',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final bool showEvents;
  final ValueChanged<bool> onChanged;

  const _Tabs({required this.showEvents, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Etkinlikler',
              active: showEvents,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Hakkında',
              active: !showEvents,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final String clubId;
  final List<ClubEvent> events;

  const _EventsTab({required this.clubId, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Bu topluluğun henüz etkinliği yok.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final event in events) ...[
          ClubEventRow(
            event: event,
            onTap: () => context.push('/club/$clubId/event/${event.id}'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  final Club club;

  const _AboutTab({required this.club});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.description.isEmpty
                ? 'Bu topluluk henüz bir tanıtım metni eklemedi.'
                : club.description,
            style: textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
