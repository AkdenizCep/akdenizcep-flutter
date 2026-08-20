import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/components/attendee_avatars.dart';
import '../../../../shared/components/event_visual.dart';
import '../../../../shared/components/progress_snackbar.dart';
import '../../../../shared/models/feed_event.dart';
import '../../../../shared/providers/event_feed_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/utils/error_message.dart';
import '../../../../shared/utils/event_category.dart';
import '../../../../shared/utils/relative_time.dart';

/// 2a etkinlik kartı — kulüp ve öğrenci etkinliklerinin ortak gösterimi.
class EventFeedCard extends ConsumerWidget {
  final FeedEvent event;
  final VoidCallback onTap;
  final VoidCallback? onAuthorTap;

  const EventFeedCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = EventCategory.resolve(
      event.category,
      fallbackText: '${event.title} ${event.description}',
    );

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventVisual(imageUrl: event.imageUrl, category: category),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _DateBadge(date: event.date),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _CategoryBadge(category: category),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthorRow(
                    event: event,
                    category: category,
                    onTap: onAuthorTap,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 19,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 14),
                  _CardFooter(event: event),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('d MMM, HH:mm', 'tr').format(date).toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final EventCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final FeedEvent event;
  final EventCategory category;
  final VoidCallback? onTap;

  const _AuthorRow({
    required this.event,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = event.isClubEvent
        ? 'Topluluk · ${relativeTime(event.createdAt)}'
        : 'Öğrenci paylaşımı · ${relativeTime(event.createdAt)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _AuthorAvatar(event: event, category: category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          Icon(
            Icons.more_horiz_rounded,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final FeedEvent event;
  final EventCategory category;

  const _AuthorAvatar({required this.event, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(15);

    if (event.isClubEvent && event.authorLogoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: event.authorLogoUrl,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
        ),
      );
    }

    if (event.isClubEvent) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.14),
          borderRadius: radius,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Icon(category.icon, size: 24, color: category.color),
      );
    }

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: category.color, borderRadius: radius),
      child: Text(
        event.authorName.isEmpty
            ? '?'
            : event.authorName.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CardFooter extends ConsumerWidget {
  final FeedEvent event;

  const _CardFooter({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final join = ref.watch(eventJoinProvider.notifier);
    ref.watch(eventJoinProvider);

    final joined = join.isJoined(event, user?.id);
    final count = join.attendeeCount(event, user?.id);

    return Row(
      children: [
        AttendeeAvatars(attendeeIds: event.attendeeIds),
        if (event.attendeeIds.isNotEmpty) const SizedBox(width: 18),
        Expanded(
          child: Text(
            count > 0 ? '+$count katılıyor' : 'İlk katılan sen ol',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _JoinButton(
          joined: joined,
          enabled: user != null && (joined || !event.isFull),
          onPressed: () async {
            if (user == null) return;
            try {
              await join.toggle(event: event, uid: user.id);
            } catch (e) {
              if (!context.mounted) return;
              showProgressSnackBar(
                context,
                message: errorMessage(e),
                icon: Icons.error_outline_rounded,
                accentColor: colorScheme.error,
              );
            }
          },
        ),
      ],
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool joined;
  final bool enabled;
  final VoidCallback onPressed;

  const _JoinButton({
    required this.joined,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: joined ? colorScheme.primaryContainer : colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: joined
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Text(
            joined ? 'Katılıyorsun' : 'Katıl',
            style: textTheme.labelLarge?.copyWith(
              color: joined
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
