import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/error_view.dart';
import '../../../../shared/components/progress_snackbar.dart';
import '../../../../shared/providers/nav_visibility_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/utils/error_message.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../models/photo_comment.dart';
import '../../providers/campus_photo_provider.dart';

/// Bir kampüs fotoğrafının yorumları — liste + alta sabit yazma çubuğu.
class PhotoCommentsSheet extends ConsumerStatefulWidget {
  final String photoId;

  const PhotoCommentsSheet({super.key, required this.photoId});

  static Future<void> show(BuildContext context, String photoId) async {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PhotoCommentsSheet(photoId: photoId),
      );
    } finally {
      container.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  @override
  ConsumerState<PhotoCommentsSheet> createState() =>
      _PhotoCommentsSheetState();
}

class _PhotoCommentsSheetState extends ConsumerState<PhotoCommentsSheet> {
  final _textController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final text = _textController.text.trim();
    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(campusPhotoServiceProvider)
          .addComment(
            photoId: widget.photoId,
            authorUid: user.id,
            authorName: user.name,
            text: text,
          );
      _textController.clear();
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
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final commentsAsync = ref.watch(photoCommentsProvider(widget.photoId));
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Yorumlar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'İlk yorumu sen yaz.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) => _CommentTile(
                        comment: comments[index],
                        isOwner: comments[index].authorUid == currentUserId,
                        onDelete: () => _deleteComment(comments[index]),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(message: errorMessage(e)),
                ),
              ),
              _CommentInputBar(
                controller: _textController,
                sending: _sending,
                onSend: _send,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteComment(PhotoComment comment) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref
          .read(campusPhotoServiceProvider)
          .deleteComment(
            photoId: widget.photoId,
            commentId: comment.id,
            authorUid: user.id,
          );
    } catch (e) {
      if (mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.error_outline_rounded,
          accentColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }
}

class _CommentTile extends StatelessWidget {
  final PhotoComment comment;
  final bool isOwner;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Text(
            comment.authorName.isNotEmpty
                ? comment.authorName[0].toUpperCase()
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    relativeTime(comment.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                comment.text,
                style: textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
        if (isOwner)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Yorum yaz...'),
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
                width: 42,
                height: 42,
                child: sending
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
