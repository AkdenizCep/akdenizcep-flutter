import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/user_provider.dart';
import '../models/profile_club_summary.dart';
import '../models/profile_event_summary.dart';
import '../models/profile_rated_meal.dart';
import '../services/profile_service.dart';
import '../services/profile_photo_service.dart';

final profileServiceProvider = Provider((_) => ProfileService());

final profilePhotoServiceProvider = Provider((_) => ProfilePhotoService());

final profilePhotoControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfilePhotoController, void>(
      ProfilePhotoController.new,
    );

class ProfilePhotoController extends AutoDisposeAsyncNotifier<void> {
  @override
  void build() {}

  Future<void> upload(Uint8List jpegBytes) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider).valueOrNull ??
          await ref.read(currentUserProvider.future);
      if (user == null || user.id.isEmpty) {
        throw Exception('Profil fotoğrafı yüklemek için oturum açmalısın.');
      }
      await ref.read(profilePhotoServiceProvider).uploadProfilePhoto(
        uid: user.id,
        jpegBytes: jpegBytes,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('ProfilePhotoController.upload hatası: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> remove() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider).valueOrNull ??
          await ref.read(currentUserProvider.future);
      if (user == null || user.id.isEmpty) {
        throw Exception('Profil fotoğrafını kaldırmak için oturum açmalısın.');
      }
      await ref
          .read(profilePhotoServiceProvider)
          .removeProfilePhoto(uid: user.id);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('ProfilePhotoController.remove hatası: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

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
