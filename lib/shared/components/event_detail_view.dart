import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_comment.dart';
import '../models/feed_event.dart';
import '../providers/event_feed_provider.dart';
import '../providers/nav_visibility_provider.dart';
import '../providers/user_provider.dart';
import '../utils/error_message.dart';
import '../utils/event_category.dart';
import '../utils/event_map_links.dart';
import '../utils/relative_time.dart';
import 'attendee_avatars.dart';
import 'error_view.dart';
import 'event_visual.dart';
import 'loading_overlay.dart';
import 'progress_snackbar.dart';

/// Ekran 1d — kulüp ve öğrenci etkinliklerinin ortak detay gövdesi.
///
/// Kulüp kartı dışarıdan enjekte edilir: kulüp verisi ve takip aksiyonu
/// community feature'ına ait olduğu için bu widget onu bilmez.
class EventDetailView extends ConsumerStatefulWidget {
  final EventRef eventRef;

  /// Kulüp etkinliklerinde gösterilen kulüp kartı. Öğrenci etkinliklerinde null.
  final Widget? clubCard;

  /// Yalnızca QR kaydı açık kulüp etkinliklerinde, kulüp yöneticisi/üyesi
  /// için dolu gelir — QR tarayıcıya götüren giriş kartı.
  final Widget? attendanceCard;

  /// Yalnızca etkinliğin sahibi için dolu gelir.
  final Future<void> Function()? onDelete;

  const EventDetailView({
    super.key,
    required this.eventRef,
    this.clubCard,
    this.attendanceCard,
    this.onDelete,
  });

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView>
    with HidesBottomNav {
  final _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventRef));

    return Scaffold(
      body: eventAsync.when(
        data: _buildContent,
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }

  Widget _buildContent(FeedEvent event) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final category = EventCategory.resolve(
      event.category,
      fallbackText: '${event.title} ${event.description}',
    );
    final user = ref.watch(currentUserProvider).valueOrNull;
    final commentsAsync = ref.watch(eventCommentsProvider(widget.eventRef));

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                event: event,
                category: category,
                isSaved: user?.savedEventIds.contains(event.id) ?? false,
                onToggleSaved: user == null
                    ? null
                    : () => _toggleSaved(user.id, event.id),
                onDelete: widget.onDelete,
              ),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 190),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // İki kart eşit yükseklikte olsun diye stretch kullanılıyor;
                      // kaydırma içinde Row'un yüksekliği sınırsız olduğundan
                      // IntrinsicHeight ile önce gerçek yükseklik ölçülmeli.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.calendar_month_rounded,
                                iconColor: colorScheme.primary,
                                label: 'TARİH',
                                value: DateFormat(
                                  'd MMMM yyyy',
                                  'tr',
                                ).format(event.date),
                                subValue: DateFormat(
                                  'EEEE, HH:mm',
                                  'tr',
                                ).format(event.date),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.location_on_rounded,
                                iconColor: colorScheme.secondary,
                                label: 'KONUM',
                                value: event.location.isEmpty
                                    ? 'Belirtilmemiş'
                                    : event.location,
                                subValue: 'Akdeniz Üniversitesi',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.clubCard != null) ...[
                        const SizedBox(height: 14),
                        widget.clubCard!,
                      ],
                      if (widget.attendanceCard != null) ...[
                        const SizedBox(height: 14),
                        widget.attendanceCard!,
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'Açıklama',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.description,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _AttendeesSection(event: event),
                      const SizedBox(height: 22),
                      _LocationSection(event: event),
                      const SizedBox(height: 22),
                      _CommentsSection(
                        commentsAsync: commentsAsync,
                        controller: _commentController,
                        sending: _sendingComment,
                        canComment: user != null,
                        onSend: () => _sendComment(event),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomCtaBar(event: event),
        ),
      ],
    );
  }

  Future<void> _toggleSaved(String uid, String eventId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final isSaved = user?.savedEventIds.contains(eventId) ?? false;

    try {
      await ref
          .read(eventFeedServiceProvider)
          .toggleSaved(uid: uid, eventId: eventId, save: !isSaved);
    } catch (e) {
      if (!mounted) return;
      showProgressSnackBar(
        context,
        message: errorMessage(e),
        icon: Icons.error_outline_rounded,
        accentColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _sendComment(FeedEvent event) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final text = _commentController.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _sendingComment = true);
    try {
      await ref
          .read(eventFeedServiceProvider)
          .addComment(
            ref: widget.eventRef,
            authorUid: user.id,
            authorName: user.name,
            text: text,
          );
      _commentController.clear();
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
      if (mounted) setState(() => _sendingComment = false);
    }
  }
}

class _Hero extends StatelessWidget {
  final FeedEvent event;
  final EventCategory category;
  final bool isSaved;
  final VoidCallback? onToggleSaved;
  final Future<void> Function()? onDelete;

  const _Hero({
    required this.event,
    required this.category,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 330,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventVisual(
            imageUrl: event.imageUrl,
            category: category,
            scrimHeight: 150,
            scrimOpacity: 0.55,
          ),
          Positioned(
            top: topInset + 8,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _CircleControl(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Geri',
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                if (onToggleSaved != null)
                  _CircleControl(
                    icon: isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: isSaved ? 'Kaydedilenlerden çıkar' : 'Kaydet',
                    onPressed: onToggleSaved!,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 10),
                  _CircleControl(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Etkinliği sil',
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 44,
            child: Row(
              children: [
                _HeroTag(
                  label: category.label.toUpperCase(),
                  color: category.color,
                ),
                const SizedBox(width: 8),
                const _HeroTag(label: 'ÜCRETSİZ', color: Color(0xFF168A5B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: const Text('Bu etkinliği silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) await onDelete!();
  }
}

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;
  final Color color;

  const _HeroTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeesSection extends ConsumerWidget {
  final FeedEvent event;

  const _AttendeesSection({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final join = ref.watch(eventJoinProvider.notifier);
    ref.watch(eventJoinProvider);
    final count = join.attendeeCount(event, user?.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Katılımcılar',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              AttendeeAvatars(
                attendeeIds: event.attendeeIds,
                size: 36,
                overlap: 10,
                maxVisible: 5,
              ),
              if (event.attendeeIds.isNotEmpty) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count kişi katılıyor',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (event.capacity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Kontenjan ${event.capacity} · '
                        '${(event.capacity! - count).clamp(0, event.capacity!)}'
                        ' yer kaldı',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final FeedEvent event;

  const _LocationSection({required this.event});

  Future<void> _openMap(BuildContext context) async {
    if (!event.hasCoordinates) {
      await _launch(context, EventMapLinks.googleMapsSearch(event.location));
      return;
    }

    final latitude = event.locationLatitude!;
    final longitude = event.locationLongitude!;
    Uri uri;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final choice = await showModalBottomSheet<_MapApp>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Text(
                    'Harita uygulamasını seç',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map_rounded),
                  title: const Text('Apple Haritalar'),
                  onTap: () => sheetContext.pop(_MapApp.apple),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: const Text('Google Maps'),
                  onTap: () => sheetContext.pop(_MapApp.google),
                ),
              ],
            ),
          ),
        ),
      );
      if (choice == null || !context.mounted) return;

      uri = choice == _MapApp.apple
          ? EventMapLinks.appleMaps(
              latitude: latitude,
              longitude: longitude,
              title: event.location,
            )
          : EventMapLinks.googleMaps(latitude: latitude, longitude: longitude);
    } else {
      uri = EventMapLinks.googleMaps(latitude: latitude, longitude: longitude);
    }

    if (context.mounted) await _launch(context, uri);
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }

    showProgressSnackBar(
      context,
      message: 'Harita uygulaması açılamadı.',
      icon: Icons.info_outline_rounded,
      accentColor: Theme.of(context).colorScheme.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konum',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: colorScheme.surfaceContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: colorScheme.secondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.location.isEmpty
                            ? 'Belirtilmemiş'
                            : event.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: !event.hasMappableLocation
                          ? null
                          : () => _openMap(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Haritada aç'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MapApp { apple, google }

class _CommentsSection extends StatelessWidget {
  final AsyncValue<List<EventComment>> commentsAsync;
  final TextEditingController controller;
  final bool sending;
  final bool canComment;
  final VoidCallback onSend;

  const _CommentsSection({
    required this.commentsAsync,
    required this.controller,
    required this.sending,
    required this.canComment,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final comments = commentsAsync.valueOrNull ?? const <EventComment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sorular',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${comments.length} yorum',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final comment in comments) ...[
          _CommentCard(comment: comment),
          const SizedBox(height: 10),
        ],
        if (canComment)
          _CommentInput(
            controller: controller,
            sending: sending,
            onSend: onSend,
          ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final EventComment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              comment.authorName.isEmpty
                  ? '?'
                  : comment.authorName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName.isEmpty
                            ? 'Öğrenci'
                            : comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      relativeTime(comment.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Bir soru sor...',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: colorScheme.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: sending ? null : onSend,
              child: SizedBox(
                width: 40,
                height: 40,
                child: sending
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCtaBar extends ConsumerWidget {
  final FeedEvent event;

  const _BottomCtaBar({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final join = ref.watch(eventJoinProvider.notifier);
    ref.watch(eventJoinProvider);

    final joined = join.isJoined(event, user?.id);
    final enabled = user != null && (joined || !event.isFull);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            background,
            background.withValues(alpha: 0.62),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ücretsiz',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Kayıt gerekli',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Material(
              color: joined
                  ? colorScheme.primaryContainer
                  : colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: enabled
                    ? () async {
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
                      }
                    : null,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: joined
                        ? Border.all(color: colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        joined
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_rounded,
                        size: 20,
                        color: joined
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        joined ? 'Katılıyorsun' : 'Katıl',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: joined
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onPrimary,
                        ),
                      ),
                    ],
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
