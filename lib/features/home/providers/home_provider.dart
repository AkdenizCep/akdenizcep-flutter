import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/academic_calendar.dart';
import '../../../shared/models/club_option.dart';
import '../../../shared/models/feed_event.dart';
import '../../../shared/providers/academic_calendar_provider.dart';
import '../../../shared/providers/event_feed_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../models/announcement.dart';
import '../services/home_service.dart';

final homeServiceProvider = Provider((_) => HomeService());

/// Karşılama alanını besleyen dakikalık nabız: selam, güneşin konumu ve
/// yarıyıl haftası uygulama açık kalsa da gün içinde güncel kalır.
final homeClockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

/// Nabza bağlı "şimdi". İlk kare için `DateTime.now()`'a düşer.
final homeNowProvider = Provider<DateTime>((ref) {
  return ref.watch(homeClockProvider).valueOrNull ?? DateTime.now();
});

/// Bugünün yarıyıl içindeki konumu; dönem arası ve yazda `null`.
final termProgressProvider = Provider<TermProgress?>((ref) {
  return ref
      .watch(academicCalendarServiceProvider)
      .termProgress(ref.watch(homeNowProvider));
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(homeServiceProvider).getAnnouncements();
});

final recommendedHomeEventsProvider = Provider<AsyncValue<List<FeedEvent>>>((
  ref,
) {
  final userAsync = ref.watch(currentUserProvider);
  final eventsAsync = ref.watch(eventFeedProvider);
  final clubsAsync = ref.watch(eventFeedClubsProvider);

  return userAsync.when(
    data: (user) => eventsAsync.when(
      data: (events) => clubsAsync.when(
        data: (clubs) => AsyncData(
          selectRecommendedHomeEvents(
            events: events,
            clubs: clubs,
            followedClubIds: user?.followedClubs ?? const [],
            now: DateTime.now(),
          ),
        ),
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
      ),
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});

List<FeedEvent> selectRecommendedHomeEvents({
  required List<FeedEvent> events,
  required List<ClubOption> clubs,
  required List<String> followedClubIds,
  required DateTime now,
  int limit = 10,
}) {
  if (followedClubIds.isEmpty || limit <= 0) return const [];

  final followedIds = followedClubIds.toSet();
  final categoriesByClubId = {
    for (final club in clubs) club.id: _normalizeCategory(club.category),
  };
  final followedCategories = followedIds
      .map((id) => categoriesByClubId[id] ?? '')
      .where((category) => category.isNotEmpty)
      .toSet();
  final followedEvents = <FeedEvent>[];
  final categoryEvents = <FeedEvent>[];
  final seen = <String>{};

  for (final event in events) {
    final clubId = event.clubId;
    if (clubId.isEmpty || event.date.isBefore(now)) continue;

    final eventKey = '$clubId/${event.id}';
    if (!seen.add(eventKey)) continue;

    if (followedIds.contains(clubId)) {
      followedEvents.add(event);
      continue;
    }

    final category = categoriesByClubId[clubId] ?? '';
    if (category.isNotEmpty && followedCategories.contains(category)) {
      categoryEvents.add(event);
    }
  }

  followedEvents.sort((a, b) => a.date.compareTo(b.date));
  categoryEvents.sort((a, b) => a.date.compareTo(b.date));
  return [...followedEvents, ...categoryEvents].take(limit).toList();
}

String _normalizeCategory(String category) => category.trim().toLowerCase();
