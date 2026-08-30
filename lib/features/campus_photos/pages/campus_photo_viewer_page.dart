import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/relative_time.dart';
import '../models/campus_photo.dart';
import '../providers/campus_photo_provider.dart';
import 'components/photo_comments_sheet.dart';

/// Kampüs fotoğrafının tam ekran hâli — ızgaradaki hücreyle aynı `Hero`
/// etiketini paylaşır. Beğeni ve yorum aksiyonları sağ alt köşede, Instagram
/// tarzı dikey bir çubukta durur.
class CampusPhotoViewerPage extends ConsumerWidget {
  final String photoId;

  const CampusPhotoViewerPage({super.key, required this.photoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(campusPhotosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: photosAsync.when(
        data: (photos) {
          final photo = photos.where((p) => p.id == photoId).firstOrNull;
          if (photo == null) {
            return const _ViewerMessage(text: 'Fotoğraf bulunamadı.');
          }
          return _PhotoView(photo: photo);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _ViewerMessage(text: errorMessage(e)),
      ),
    );
  }
}

class _PhotoView extends ConsumerWidget {
  final CampusPhoto photo;

  const _PhotoView({required this.photo});

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.id;
    if (uid == null) return;
    await ref
        .read(photoLikeProvider.notifier)
        .toggle(photo: photo, uid: uid);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.id;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fotoğrafı Sil'),
        content: const Text('Bu fotoğrafı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Silme başarılı olur olmaz `campusPhotosProvider` akışı bu fotoğrafı
    // listeden düşürür ve sayfa "Fotoğraf bulunamadı" durumuna geçer — bu,
    // aşağıdaki `await` bitmeden ÖNCE gerçekleşebilir ve o an bu widget'ın
    // (`_PhotoView`) context'i ağaçtan kaldırılmış olur. Router ve mesajı bu
    // yüzden `await`'ten ÖNCE, context hâlâ kesin geçerliyken yakalanır.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await ref
          .read(campusPhotoServiceProvider)
          .deletePhoto(photoId: photo.id, authorUid: uid);
      router.pop();
      showProgressSnackBar(
        // ignore: use_build_context_synchronously
        context,
        messenger: messenger,
        message: 'Fotoğraf silindi.',
        // Varsayılan floating davranışı FAB'ın üstüne çıkmasın diye bildirimi
        // yükseğe kaldırıyor; geri dönülen listede FAB olduğu için burada
        // yüzen alt nav çubuğuna yakın, sabit bir konum veriliyor.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      );
    } catch (e) {
      showProgressSnackBar(
        // ignore: use_build_context_synchronously
        context,
        messenger: messenger,
        message: errorMessage(e),
        icon: Icons.error_outline_rounded,
        accentColor: colorScheme.error,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final isOwner = currentUserId != null && currentUserId == photo.authorUid;
    ref.watch(photoLikeProvider);
    final likeNotifier = ref.read(photoLikeProvider.notifier);
    final liked = likeNotifier.isLiked(photo, currentUserId);
    final likeCount = likeNotifier.likeCount(photo, currentUserId);
    final commentsAsync = ref.watch(photoCommentsProvider(photo.id));
    final commentCount = commentsAsync.valueOrNull?.length ?? 0;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Hero(
                  tag: 'campus-photo-${photo.id}',
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
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
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: _TopBar(
              photo: photo,
              isOwner: isOwner,
              onClose: () => context.pop(),
              onDelete: () => _delete(context, ref),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: _ActionBar(
              liked: liked,
              likeCount: likeCount,
              commentCount: commentCount,
              onLike: () => _toggleLike(context, ref),
              onComment: () => PhotoCommentsSheet.show(context, photo.id),
            ),
          ),
          if (photo.caption.isNotEmpty)
            Positioned(
              left: 16,
              right: 88,
              bottom: 28,
              child: Text(
                photo.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final CampusPhoto photo;
  final bool isOwner;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _TopBar({
    required this.photo,
    required this.isOwner,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  relativeTime(photo.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool liked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _ActionBar({
    required this.liked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: liked ? const Color(0xFFE0245E) : Colors.white,
          label: '$likeCount',
          onTap: onLike,
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          iconColor: Colors.white,
          label: '$commentCount',
          onTap: onComment,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
        ],
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
