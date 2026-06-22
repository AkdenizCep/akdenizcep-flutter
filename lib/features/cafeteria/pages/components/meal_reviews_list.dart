import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/providers/user_provider.dart';
import '../../models/meal_review.dart';
import '../../providers/cafeteria_provider.dart';

class MealReviewsList extends ConsumerWidget {
  final String mealType;

  const MealReviewsList({super.key, required this.mealType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(mealReviewsProvider(mealType));
    final colorScheme = Theme.of(context).colorScheme;
    final currentUid = ref.watch(currentUserProvider).valueOrNull?.id;

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Text(
            'Henüz yorum yok, ilk yorumu sen yaz!',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < reviews.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ReviewRow(
                review: reviews[i],
                mealType: mealType,
                currentUid: currentUid,
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReviewRow extends ConsumerWidget {
  final MealReview review;
  final String mealType;
  final String? currentUid;

  const _ReviewRow({
    required this.review,
    required this.mealType,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = review.authorName.isNotEmpty
        ? review.authorName[0].toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                color: colorScheme.primary,
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
                        review.authorName.isNotEmpty
                            ? review.authorName
                            : 'Bir öğrenci',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _relativeCreatedAt(review.createdAt),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: i < review.rating
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant,
                    );
                  }),
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.comment,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _VoteControls(
                  review: review,
                  currentUid: currentUid,
                  isOwnReview: currentUid != null && currentUid == review.uid,
                  onVote: (value) => _handleVote(context, ref, value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVote(
    BuildContext context,
    WidgetRef ref,
    int value,
  ) async {
    final uid = currentUid;
    if (uid == null) return;

    final date = ref.read(formattedDateProvider);
    final nextValue = review.voteOf(uid) == value ? 0 : value;

    try {
      await ref
          .read(cafeteriaServiceProvider)
          .voteReview(
            date: date,
            mealName: mealType,
            reviewUid: review.uid,
            voterUid: uid,
            value: nextValue,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _relativeCreatedAt(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';

    return DateFormat('d MMMM', 'tr').format(createdAt);
  }
}

class _VoteControls extends StatelessWidget {
  final MealReview review;
  final String? currentUid;
  final bool isOwnReview;
  final ValueChanged<int> onVote;

  const _VoteControls({
    required this.review,
    required this.currentUid,
    required this.isOwnReview,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myVote = currentUid != null ? review.voteOf(currentUid!) : 0;
    final enabled = currentUid != null && !isOwnReview;
    final upActive = myVote == 1;
    final downActive = myVote == -1;

    return Opacity(
      opacity: isOwnReview ? 0.4 : 1,
      child: Row(
        children: [
          _VoteButton(
            icon: Icons.thumb_up_alt_rounded,
            active: upActive,
            activeColor: colorScheme.primary,
            onPressed: enabled ? () => onVote(1) : null,
          ),
          const SizedBox(width: 4),
          Text(
            review.score == 0 ? 'Faydalı mı?' : '${review.score}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          _VoteButton(
            icon: Icons.thumb_down_alt_rounded,
            active: downActive,
            activeColor: colorScheme.error,
            onPressed: enabled ? () => onVote(-1) : null,
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback? onPressed;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: active ? activeColor : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
