import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/daily_menu.dart';
import '../models/meal_rating.dart';
import '../models/meal_review.dart';
import '../services/cafeteria_service.dart';

final cafeteriaServiceProvider = Provider((_) => CafeteriaService());

final selectedDateProvider = StateProvider<DateTime>((_) => DateTime.now());

final formattedDateProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

final menuProvider = StreamProvider<DailyMenu>((ref) {
  final date = ref.watch(formattedDateProvider);
  return ref.watch(cafeteriaServiceProvider).getMenu(date);
});

/// Menu satirlarinin ayristirilmis hali (ad + varsa kalori).
final menuEntriesProvider = Provider<List<MenuEntry>>((ref) {
  final menu = ref.watch(menuProvider).valueOrNull;
  if (menu == null) return const [];
  return menu.items.map(MenuEntry.parse).toList();
});

/// Secili gunun puan ozeti. Henuz oy verilmemisse `null`.
final ratingProvider = StreamProvider<MealRating?>((ref) {
  final date = ref.watch(formattedDateProvider);
  return ref.watch(cafeteriaServiceProvider).getRating(date);
});

final reviewsProvider = StreamProvider<List<MealReview>>((ref) {
  final date = ref.watch(formattedDateProvider);
  return ref.watch(cafeteriaServiceProvider).getReviews(date);
});
