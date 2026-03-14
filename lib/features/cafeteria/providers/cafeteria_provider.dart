import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/meal_rating.dart';
import '../models/menu_item.dart';
import '../services/cafeteria_service.dart';

final cafeteriaServiceProvider = Provider((_) => CafeteriaService());

final selectedDateProvider = StateProvider<DateTime>((_) => DateTime.now());

final formattedDateProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

final menuProvider = StreamProvider<List<MenuItem>>((ref) {
  final date = ref.watch(formattedDateProvider);
  return ref.watch(cafeteriaServiceProvider).getMenu(date);
});

final ratingsProvider = StreamProvider<List<MealRating>>((ref) {
  final date = ref.watch(formattedDateProvider);
  return ref.watch(cafeteriaServiceProvider).getRatings(date);
});
