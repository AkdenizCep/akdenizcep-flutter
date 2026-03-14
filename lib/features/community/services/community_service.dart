import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';
import '../models/club_event.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Club>> getClubs() {
    return _db.collection('clubs').snapshots().map(
          (snap) => snap.docs
              .map((d) => Club.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<Club> getClub(String clubId) {
    return _db.collection('clubs').doc(clubId).snapshots().map(
          (snap) => Club.fromJson(snap.data()!..['id'] = snap.id),
        );
  }

  Stream<List<ClubEvent>> getClubEvents(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('club-events')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClubEvent.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> followClub(String uid, String clubId) async {
    try {
      final batch = _db.batch();

      batch.update(_db.collection('users').doc(uid), {
        'followedClubs': FieldValue.arrayUnion([clubId]),
      });
      batch.update(_db.collection('clubs').doc(clubId), {
        'followerCount': FieldValue.increment(1),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Kulup takip edilemedi: ${e.message}');
    }
  }

  Future<void> unfollowClub(String uid, String clubId) async {
    try {
      final batch = _db.batch();

      batch.update(_db.collection('users').doc(uid), {
        'followedClubs': FieldValue.arrayRemove([clubId]),
      });
      batch.update(_db.collection('clubs').doc(clubId), {
        'followerCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Kulup takipten cikilamadi: ${e.message}');
    }
  }
}
