import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/error_message.dart';
import '../models/announcement.dart';
import '../providers/home_provider.dart';

/// Duyuru görselinin tam ekran, yakınlaştırılabilir hâli.
///
/// [AnnouncementDetailPage]'deki kapak görseline dokunulunca açılır; ikisi
/// aynı `Hero` etiketini paylaştığı için gecis akici bir buyume animasyonu
/// olur. Zemin bilerek siyah — tema rengine bağlı kalmıyor, bir foto
/// galerisi gibi davranıyor.
class AnnouncementImageViewerPage extends ConsumerWidget {
  final String announcementId;

  const AnnouncementImageViewerPage({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          final announcement = announcements
              .where((a) => a.id == announcementId)
              .firstOrNull;
          if (announcement == null) {
            return const _ViewerMessage(text: 'Duyuru bulunamadı.');
          }
          return _ZoomableImage(announcement: announcement);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _ViewerMessage(text: errorMessage(e)),
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  final Announcement announcement;

  const _ZoomableImage({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Hero(
          tag: 'announcement-image-${announcement.id}',
          child: CachedNetworkImage(
            imageUrl: announcement.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  final String text;

  const _ViewerMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
