import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../firebase_options.dart';
import '../models/meal_rating.dart';
import '../models/meal_review.dart';
import '../models/menu_item.dart';

class CafeteriaService {
  final _db = FirebaseFirestore.instance;
  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.databaseURL,
  ).ref();

  Stream<List<MenuItem>> getMenu(String date) {
    return _rtdb.child('cafeteria_menu').child(date).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <MenuItem>[];

      return data.entries.map((entry) {
        return MenuItem(
          date: date,
          mealType: entry.key as String,
          items: List<String>.from(entry.value as List),
        );
      }).toList();
    });
  }

  Stream<List<MealRating>> getRatings(String date) {
    return _db
        .collection('cafeteria_ratings')
        .where('date', isEqualTo: date)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MealRating.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<List<MealReview>> getReviews(String date, String mealName) {
    final docId = '${date}_$mealName';
    return _db
        .collection('cafeteria_ratings')
        .doc(docId)
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final reviews = snap.docs
              .map((d) => MealReview.fromJson(d.data()..['uid'] = d.id))
              .toList();
          reviews.sort((a, b) {
            final scoreDiff = b.score.compareTo(a.score);
            if (scoreDiff != 0) return scoreDiff;
            return b.createdAt.compareTo(a.createdAt);
          });
          return reviews;
        });
  }

  /// Bir yoruma upvote/downvote verir. [value] 1 (faydalı), -1 (faydasız)
  /// veya 0 (oyu geri al) olabilir. Kullanıcı kendi yorumuna oy veremez.
  Future<void> voteReview({
    required String date,
    required String mealName,
    required String reviewUid,
    required String voterUid,
    required int value,
  }) async {
    if (reviewUid == voterUid) {
      throw Exception('Kendi yorumunuza oy veremezsiniz.');
    }

    final docId = '${date}_$mealName';
    final reviewRef = _db
        .collection('cafeteria_ratings')
        .doc(docId)
        .collection('ratings')
        .doc(reviewUid);

    try {
      if (value == 0) {
        await reviewRef.update({'votes.$voterUid': FieldValue.delete()});
      } else {
        await reviewRef.update({'votes.$voterUid': value});
      }
    } on FirebaseException catch (e) {
      throw Exception('Oy verilemedi: ${e.message}');
    }
  }

  /// Kullanicinin ayni gune ait rating'i varsa islem reddedilir.
  /// avgRating ve ratingCount atomik olarak transaction ile guncellenir.
  Future<void> rateMeal({
    required String uid,
    required String date,
    required String mealName,
    required int rating,
    required String authorName,
    String comment = '',
  }) async {
    final docId = '${date}_$mealName';
    final ratingDocRef = _db
        .collection('cafeteria_ratings')
        .doc(docId)
        .collection('ratings')
        .doc(uid);

    try {
      final existingRating = await ratingDocRef.get();
      if (existingRating.exists) {
        throw Exception('Bu yemege bugun zaten oy verdiniz.');
      }

      await _db.runTransaction((transaction) async {
        final mealRef = _db.collection('cafeteria_ratings').doc(docId);
        final mealSnap = await transaction.get(mealRef);

        double currentAvg = 0;
        int currentCount = 0;

        if (mealSnap.exists) {
          currentAvg = (mealSnap.data()?['avgRating'] as num?)?.toDouble() ?? 0;
          currentCount = mealSnap.data()?['ratingCount'] as int? ?? 0;
        }

        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + rating) / newCount;

        transaction.set(mealRef, {
          'mealName': mealName,
          'date': date,
          'avgRating': newAvg,
          'ratingCount': newCount,
        }, SetOptions(merge: true));

        transaction.set(ratingDocRef, {
          'rating': rating,
          'comment': comment,
          'authorName': authorName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Oy verilemedi: ${e.message}');
    }
  }
}
