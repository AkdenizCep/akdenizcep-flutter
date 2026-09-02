import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_option.dart';
import '../models/event_comment.dart';
import '../models/feed_event.dart';
import '../services/event_feed_service.dart';
import '../utils/event_category.dart';
import 'user_provider.dart';

/// 2a akışındaki kaynak filtresi.
enum EventSourceFilter { club, student }

final eventFeedServiceProvider = Provider((_) => EventFeedService());

final eventFeedProvider = StreamProvider<List<FeedEvent>>((ref) {
  return ref.watch(eventFeedServiceProvider).getFeed();
});

final eventFeedClubsProvider = StreamProvider<List<ClubOption>>((ref) {
  return ref.watch(eventFeedServiceProvider).getClubs();
});

final eventDetailProvider = StreamProvider.family<FeedEvent, EventRef>((
  ref,
  eventRef,
) {
  return ref.watch(eventFeedServiceProvider).getEvent(eventRef);
});

final eventCommentsProvider =
    StreamProvider.family<List<EventComment>, EventRef>((ref, eventRef) {
      return ref.watch(eventFeedServiceProvider).getComments(eventRef);
    });

/// Oturumdaki kullanıcının yöneticisi olduğu kulüpler.
final adminClubsProvider = StreamProvider<List<ClubOption>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(const <ClubOption>[]);

  return ref.watch(eventFeedServiceProvider).getAdminClubs(user.id);
});

// --- Katılım (optimistic) -------------------------------------------------

/// Firestore yazımı tamamlanana kadar butonun anında tepki vermesini sağlayan
/// geçici katılım durumu. Anahtar: etkinlik id'si.
class EventJoinNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  bool isJoined(FeedEvent event, String? uid) =>
      state[event.id] ?? event.isJoinedBy(uid);

  /// Ekranda gösterilecek katılımcı sayısı — bekleyen değişiklik varsa ±1.
  int attendeeCount(FeedEvent event, String? uid) {
    final pending = state[event.id];
    if (pending == null) return event.attendeeCount;

    final actual = event.isJoinedBy(uid);
    if (pending == actual) return event.attendeeCount;
    return (event.attendeeCount + (pending ? 1 : -1)).clamp(0, 1 << 30);
  }

  Future<void> toggle({required FeedEvent event, required String uid}) async {
    final next = !isJoined(event, uid);
    state = {...state, event.id: next};

    try {
      await ref
          .read(eventFeedServiceProvider)
          .toggleJoin(ref: event.ref, uid: uid, join: next);
    } finally {
      // Yazma bittiğinde (ya da hata aldığında) gerçek veri devralır.
      state = {...state}..remove(event.id);
    }
  }
}

final eventJoinProvider =
    NotifierProvider<EventJoinNotifier, Map<String, bool>>(
      EventJoinNotifier.new,
    );

// --- 2a filtre state'leri -------------------------------------------------

final selectedCategoryProvider = StateProvider<String>(
  (_) => EventCategory.all.id,
);

final selectedSourceProvider = StateProvider<EventSourceFilter>(
  (_) => EventSourceFilter.club,
);

final feedSearchQueryProvider = StateProvider<String>((_) => '');

/// Kategori × kaynak × arama — üçü AND ile birleşir.
final filteredFeedProvider = Provider<AsyncValue<List<FeedEvent>>>((ref) {
  final feed = ref.watch(eventFeedProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final sourceFilter = ref.watch(selectedSourceProvider);
  final query = ref.watch(feedSearchQueryProvider).trim().toLowerCase();

  return feed.whenData((events) {
    return events.where((event) {
      if (sourceFilter == EventSourceFilter.club && !event.isClubEvent) {
        return false;
      }
      if (sourceFilter == EventSourceFilter.student && event.isClubEvent) {
        return false;
      }

      if (categoryId != EventCategory.all.id) {
        final resolved = EventCategory.resolve(
          event.category,
          fallbackText: '${event.title} ${event.description}',
        );
        if (resolved.id != categoryId) return false;
      }

      if (query.isEmpty) return true;
      return event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query);
    }).toList();
  });
});
