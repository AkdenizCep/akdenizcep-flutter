import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../auth/models/app_user.dart';
import '../models/meal_rating.dart';
import '../models/menu_item.dart';
import '../providers/cafeteria_provider.dart';
import 'components/cafeteria_empty_state.dart';
import 'components/cafeteria_header.dart';
import 'components/cafeteria_info_sheet.dart';
import 'components/date_strip.dart';
import 'components/meal_hero_card.dart';
import 'components/meal_reviews_list.dart';
import 'components/meal_type_segment.dart';
import 'components/rate_meal_sheet.dart';
import 'components/rating_row.dart';

class CafeteriaPage extends ConsumerWidget {
  const CafeteriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final ratingsAsync = ref.watch(ratingsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: menuAsync.when(
          data: (menus) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CafeteriaHeader(
                        onPickDate: () => _pickDate(context, ref, selectedDate),
                        onShowInfo: () => _showInfoSheet(context, ref),
                      ),
                      const SizedBox(height: 22),
                      DateStrip(
                        selectedDate: selectedDate,
                        onChanged: (date) {
                          ref.read(selectedDateProvider.notifier).state = date;
                        },
                      ),
                    ],
                  ),
                ),
                if (menus.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: CafeteriaEmptyState(date: selectedDate),
                  )
                else
                  _buildMenuContent(
                    context,
                    ref,
                    menus,
                    ratingsAsync.valueOrNull ?? const [],
                    currentUser,
                  ),
              ],
            );
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: errorMessage(e)),
        ),
      ),
    );
  }

  Widget _buildMenuContent(
    BuildContext context,
    WidgetRef ref,
    List<MenuItem> menus,
    List<MealRating> ratings,
    AppUser? currentUser,
  ) {
    final mealTypes = menus.map((m) => m.mealType).toList();
    final selectedMealType = ref.watch(selectedMealTypeProvider);
    final activeMealType = mealTypes.contains(selectedMealType)
        ? selectedMealType!
        : mealTypes.first;
    final activeMenu = menus.firstWhere((m) => m.mealType == activeMealType);

    final matchingRating = ratings.where((r) => r.mealName == activeMealType);
    final avgRating = matchingRating.isNotEmpty
        ? matchingRating.first.avgRating
        : null;
    final ratingCount = matchingRating.isNotEmpty
        ? matchingRating.first.ratingCount
        : 0;

    final selectedDate = ref.read(selectedDateProvider);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        22,
        26,
        22,
        132 + MediaQuery.of(context).padding.bottom,
      ),
      sliver: SliverList.list(
        children: [
          Text(
            DateFormat('d MMMM EEEE', 'tr').format(selectedDate).toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          if (mealTypes.length > 1) ...[
            MealTypeSegment(
              mealTypes: mealTypes,
              selected: activeMealType,
              onChanged: (mealType) {
                ref.read(selectedMealTypeProvider.notifier).state = mealType;
              },
            ),
            const SizedBox(height: 22),
          ],
          MealHeroCard(
            menu: activeMenu,
            avgRating: avgRating,
            ratingCount: ratingCount,
          ),
          const SizedBox(height: 18),
          RatingRow(
            avgRating: avgRating,
            enabled: currentUser != null,
            onStarTap: (rating) => _openRateSheet(
              context,
              ref,
              currentUser,
              selectedDate,
              activeMealType,
              rating,
            ),
          ),
          const SizedBox(height: 18),
          MealReviewsList(mealType: activeMealType),
        ],
      ),
    );
  }

  Future<void> _showInfoSheet(BuildContext context, WidgetRef ref) async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const CafeteriaInfoSheet(),
      );
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _openRateSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser? currentUser,
    DateTime selectedDate,
    String mealType,
    int initialRating,
  ) async {
    if (currentUser == null) return;
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => RateMealSheet(
          initialRating: initialRating,
          onSubmit: (rating, comment) => _rateMeal(
            context,
            ref,
            currentUser,
            selectedDate,
            mealType,
            rating,
            comment,
          ),
        ),
      );
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _rateMeal(
    BuildContext context,
    WidgetRef ref,
    AppUser? currentUser,
    DateTime selectedDate,
    String mealType,
    int rating,
    String comment,
  ) async {
    if (currentUser == null) return;
    try {
      await ref
          .read(cafeteriaServiceProvider)
          .rateMeal(
            uid: currentUser.id,
            date: DateFormat('yyyy-MM-dd').format(selectedDate),
            mealName: mealType,
            rating: rating,
            authorName: currentUser.name,
            comment: comment,
          );
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: 'Teşekkürler! Oyunuz kaydedildi.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: errorMessage(e),
          icon: Icons.info_rounded,
          accentColor: Theme.of(context).colorScheme.secondary,
        );
      }
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      ref.read(selectedDateProvider.notifier).state = date;
    }
  }
}
