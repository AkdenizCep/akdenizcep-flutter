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
import '../providers/cafeteria_provider.dart';
import 'components/cafeteria_date_sheet.dart';
import 'components/cafeteria_hero.dart';
import 'components/cafeteria_info_sheet.dart';
import 'components/meal_reviews_list.dart';
import 'components/menu_card.dart';
import 'components/rate_meal_sheet.dart';
import 'components/score_card.dart';

class CafeteriaPage extends ConsumerWidget {
  const CafeteriaPage({super.key});

  /// Menusu goruntulenebilen aralik. Universite menuyu bir hafta oncesinden
  /// giriyor; geriye dogru gecmis menuler puanlariyla birlikte kaliyor.
  static const _daysBack = 30;
  static const _daysForward = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final entries = ref.watch(menuEntriesProvider);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CafeteriaHero(
              date: selectedDate,
              subtitle: menuAsync.isLoading
                  ? 'Yükleniyor…'
                  : entries.isEmpty
                  ? 'Menü girilmemiş'
                  : '${entries.length} çeşit · Günün menüsü',
              onPreviousDay: _canGoTo(selectedDate, -1)
                  ? () => _shiftDay(ref, selectedDate, -1)
                  : null,
              onNextDay: _canGoTo(selectedDate, 1)
                  ? () => _shiftDay(ref, selectedDate, 1)
                  : null,
              onPickDate: () => _pickDate(context, ref, selectedDate),
              onShowInfo: () => _showInfoSheet(context, ref),
            ),
            // Kartlar basligin uzerine biner. Transform yerlesimi degistirmedigi
            // icin alttaki bosluktan ayni miktar dusuluyor.
            Transform.translate(
              offset: const Offset(0, -CafeteriaHero.overlap),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  130 + bottomInset - CafeteriaHero.overlap,
                ),
                child: menuAsync.when(
                  data: (_) => _MenuBody(date: selectedDate),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: LoadingOverlay(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorView(message: errorMessage(e)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _canGoTo(DateTime from, int deltaDays) {
    final target = DateUtils.dateOnly(from).add(Duration(days: deltaDays));
    final today = DateUtils.dateOnly(DateTime.now());
    return !target.isBefore(today.subtract(const Duration(days: _daysBack))) &&
        !target.isAfter(today.add(const Duration(days: _daysForward)));
  }

  static void _shiftDay(WidgetRef ref, DateTime from, int deltaDays) {
    ref.read(selectedDateProvider.notifier).state = DateUtils.dateOnly(
      from,
    ).add(Duration(days: deltaDays));
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());

    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      final date = await CafeteriaDateSheet.show(
        context,
        selectedDate: DateUtils.dateOnly(selectedDate),
        firstDate: today.subtract(const Duration(days: _daysBack)),
        lastDate: today.add(const Duration(days: _daysForward)),
      );
      if (date != null) {
        ref.read(selectedDateProvider.notifier).state = date;
      }
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
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
}

class _MenuBody extends ConsumerWidget {
  final DateTime date;

  const _MenuBody({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(menuEntriesProvider);
    final rating = ref.watch(ratingProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenuCard(entries: entries, date: date),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 14),
          ScoreCard(
            rating: rating,
            canRate: currentUser != null,
            onRate: () => _openRateSheet(context, ref, currentUser),
          ),
        ],
        const MealReviewsList(),
      ],
    );
  }

  Future<void> _openRateSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser? currentUser,
  ) async {
    if (currentUser == null) return;

    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => RateMealSheet(
          onSubmit: (rating, comment) =>
              _rateMeal(context, ref, currentUser, rating, comment),
        ),
      );
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _rateMeal(
    BuildContext context,
    WidgetRef ref,
    AppUser currentUser,
    int rating,
    String comment,
  ) async {
    try {
      await ref
          .read(cafeteriaServiceProvider)
          .rateMeal(
            uid: currentUser.id,
            date: DateFormat('yyyy-MM-dd').format(date),
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
}
