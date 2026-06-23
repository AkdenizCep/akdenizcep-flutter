import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_club_summary.dart';
import '../models/profile_event_summary.dart';
import '../models/profile_rated_meal.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  Stream<List<ProfileClubSummary>> getFollowedClubs(List<String> clubIds) {
    if (clubIds.isEmpty) return Stream.value(const []);

    return _db
        .collection('clubs')
        .where(FieldPath.documentId, whereIn: clubIds)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProfileClubSummary.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<List<ProfileEventSummary>> getMyEvents(String uid) {
    return _db
        .collection('student-events')
        .where('authorUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final events = snap.docs
              .map((d) => ProfileEventSummary.fromJson(d.data()..['id'] = d.id))
              .toList();
          events.sort((a, b) => b.date.compareTo(a.date));
          return events;
        });
  }

  /// [mealDocIds], users/{uid}.ratedMealIds alanindan gelir (her biri
  /// '${date}_$mealName' formatinda). Sorgu degil dogrudan get() kullanir,
  /// boylece collection-group index gerektirmez.
  Future<List<ProfileRatedMeal>> getMyRatedMeals(
    String uid,
    List<String> mealDocIds,
  ) async {
    if (mealDocIds.isEmpty) return const [];

    final snapshots = await Future.wait(
      mealDocIds.map(
        (docId) => _db
            .collection('cafeteria_ratings')
            .doc(docId)
            .collection('ratings')
            .doc(uid)
            .get(),
      ),
    );

    final meals = snapshots
        .where((snap) => snap.exists)
        .map((snap) => ProfileRatedMeal.fromJson(snap.data()!))
        .toList();
    meals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return meals;
  }
}
