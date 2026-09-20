import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/relative_time.dart';
import '../../../shared/utils/system_nav_inset.dart';
import '../models/campus_photo.dart';
import '../providers/campus_photo_provider.dart';
import 'components/photo_comments_sheet.dart';

class CampusPhotosPage extends ConsumerWidget {
  const CampusPhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(campusPhotosProvider);
    final extraLift = systemNavExtraLift(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kampüs Fotoğrafları')),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + extraLift),
            itemCount: photos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _PhotoPost(photo: photos[index]),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 10 + extraLift),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/campus/photos/create'),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Paylaş'),
        ),
      ),
    );
  }
}

class _PhotoPost extends ConsumerWidget {
  final CampusPhoto photo;

  const _PhotoPost({required this.photo});

  Future<void> _toggleLike(WidgetRef ref) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.id;
    if (uid == null) return;
    await ref.read(photoLikeProvider.notifier).toggle(photo: photo, uid: uid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.watch(photoLikeProvider);
    final likeNotifier = ref.read(photoLikeProvider.notifier);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final liked = likeNotifier.isLiked(photo, currentUserId);
    final likeCount = likeNotifier.likeCount(photo, currentUserId);
    final commentCount =
        ref.watch(photoCommentsProvider(photo.id)).valueOrNull?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  photo.authorName.isNotEmpty
                      ? photo.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      relativeTime(photo.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go('/campus/photos/${photo.id}'),
            child: Hero(
              tag: 'campus-photo-${photo.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: colorScheme.surfaceContainerHighest),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatAction(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: liked ? const Color(0xFFE0245E) : colorScheme.onSurface,
                label: likeCount > 0 ? '$likeCount' : null,
                onTap: () => _toggleLike(ref),
              ),
              const SizedBox(width: 18),
              _StatAction(
                icon: Icons.mode_comment_outlined,
                iconColor: colorScheme.onSurface,
                label: commentCount > 0 ? '$commentCount' : null,
                onTap: () => PhotoCommentsSheet.show(context, photo.id),
              ),
            ],
          ),
          if (photo.caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${photo.authorName} ',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: photo.caption, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? label;
  final VoidCallback onTap;

  const _StatAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz paylaşılan fotoğraf yok.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
