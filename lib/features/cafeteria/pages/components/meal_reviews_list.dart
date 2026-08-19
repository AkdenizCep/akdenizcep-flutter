import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/utils/error_message.dart';
import '../../models/meal_review.dart';
import '../../providers/cafeteria_provider.dart';
import 'cafeteria_card.dart';
import 'score_card.dart';

/// Secili gunun yorumlari. Yorum yoksa hicbir sey cizmez — bos bir baslik
/// birakmamak icin baslik da bu bilesenin icinde.
class MealReviewsList extends ConsumerWidget {
  const MealReviewsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUid = ref.watch(currentUserProvider).valueOrNull?.id;

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
              child: Text(
                'YORUMLAR',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            for (var i = 0; i < reviews.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ReviewCard(review: reviews[i], currentUid: currentUid),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final MealReview review;
  final String? currentUid;

  const _ReviewCard({required this.review, required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = review.authorName.isNotEmpty
        ? review.authorName[0].toUpperCase()
        : '?';

    return CafeteriaCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeCreatedAt(review.createdAt),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                StarRow(value: review.rating.toDouble(), size: 14),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.comment,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.48,
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
            reviewUid: review.uid,
            voterUid: uid,
            value: nextValue,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
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

    return Opacity(
      opacity: isOwnReview ? 0.4 : 1,
      child: Row(
        children: [
          _VoteButton(
            icon: Icons.thumb_up_alt_rounded,
            active: myVote == 1,
            activeColor: colorScheme.primary,
            onPressed: enabled ? () => onVote(1) : null,
          ),
          const SizedBox(width: 4),
          Text(
            review.score == 0 ? 'Faydalı mı?' : '${review.score}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          _VoteButton(
            icon: Icons.thumb_down_alt_rounded,
            active: myVote == -1,
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
