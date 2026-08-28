import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/relative_time.dart';
import '../models/announcement.dart';
import '../providers/home_provider.dart';

/// Duyuru detayı — kulüp/öğrenci etkinlik detayıyla aynı dili konuşur:
/// sabit boy kapak görseli + üstüne binen yuvarlak köşeli içerik sayfası
/// (bkz. `shared/components/event_detail_view.dart`'taki _Hero). Model
/// ayrı bir gövde metni taşımadığı için içerik yalnızca başlık ve tarih —
/// asıl bilgi çoğunlukla görselin kendisinde, o yüzden görsele dokununca
/// tam ekran yakınlaştırılabilir görünüme geçiliyor.
class AnnouncementDetailPage extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailPage({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      body: announcementsAsync.when(
        data: (announcements) {
          final announcement = announcements
              .where((a) => a.id == announcementId)
              .firstOrNull;
          if (announcement == null) {
            return const ErrorView(message: 'Duyuru bulunamadı.');
          }
          return _DetailContent(announcement: announcement);
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Announcement announcement;

  const _DetailContent({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnnouncementHero(announcement: announcement),
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
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                32 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.28),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        relativeTime(announcement.createdAt),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementHero extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementHero({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () =>
                context.push('/announcements/${announcement.id}/image'),
            child: Hero(
              tag: 'announcement-image-${announcement.id}',
              child: CachedNetworkImage(
                imageUrl: announcement.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          // Alt bolge icerik sayfasiyla kaynasin diye koyulasan bir gecis.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black45],
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 16,
            child: _CircleIcon(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Geri',
              onPressed: () => context.pop(),
            ),
          ),
          if (announcement.context.isNotEmpty)
            Positioned(
              left: 20,
              bottom: 44,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  announcement.context.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleIcon({
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
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
