import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/user_provider.dart';
import '../models/profile_club_summary.dart';
import '../models/profile_event_summary.dart';
import '../models/profile_rated_meal.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((_) => ProfileService());

final followedClubsProvider = StreamProvider<List<ProfileClubSummary>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.followedClubs.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(profileServiceProvider).getFollowedClubs(user.followedClubs);
});

final myEventsProvider = StreamProvider<List<ProfileEventSummary>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(profileServiceProvider).getMyEvents(user.id);
});

final myRatedMealsProvider = FutureProvider<List<ProfileRatedMeal>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Future.value(const []);
  return ref
      .watch(profileServiceProvider)
      .getMyRatedMeals(user.id, user.ratedMealIds);
});
