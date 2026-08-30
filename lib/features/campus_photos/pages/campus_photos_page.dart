import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/relative_time.dart';
import '../models/campus_photo.dart';
import '../providers/campus_photo_provider.dart';
import 'components/photo_comments_sheet.dart';

class CampusPhotosPage extends ConsumerWidget {
  const CampusPhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(campusPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kampüs Fotoğrafları')),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
            itemCount: photos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _PhotoPost(photo: photos[index]),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
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

    ref.watch(photoLikeProvider);
    final likeNotifier = ref.read(photoLikeProvider.notifier);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final liked = likeNotifier.isLiked(photo, currentUserId);
    final likeCount = likeNotifier.likeCount(photo, currentUserId);
    final commentCount =
        ref.watch(photoCommentsProvider(photo.id)).valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Text(
                  photo.authorName.isNotEmpty
                      ? photo.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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
        ),
        GestureDetector(
          onTap: () => context.go('/campus/photos/${photo.id}'),
          child: Hero(
            tag: 'campus-photo-${photo.id}',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _toggleLike(ref),
                icon: Icon(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: liked ? const Color(0xFFE0245E) : colorScheme.onSurface,
                ),
              ),
              if (likeCount > 0)
                Text(
                  '$likeCount',
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => PhotoCommentsSheet.show(context, photo.id),
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              if (commentCount > 0)
                Text(
                  '$commentCount',
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        if (photo.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${photo.authorName} ',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: photo.caption,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
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
