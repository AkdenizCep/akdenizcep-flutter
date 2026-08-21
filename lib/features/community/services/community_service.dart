import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_record.dart';
import '../models/club.dart';
import '../models/club_event.dart';
import '../models/club_member.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Club>> getClubs() {
    return _db
        .collection('clubs')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Club.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<Club> getClub(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .snapshots()
        .map((snap) => Club.fromJson(snap.data()!..['id'] = snap.id));
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
      throw Exception('Topluluk takip edilemedi: ${e.message}');
    }
  }

  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    try {
      await _db.collection('clubs').doc(clubId).update(data);
    } on FirebaseException catch (e) {
      throw Exception('Topluluk güncellenemedi: ${e.message}');
    }
  }

  Stream<List<ClubMember>> getClubMembers(String clubId) {
    return _db
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .orderBy('addedAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ClubMember.fromJson(d.data())).toList(),
        );
  }

  /// Öğrenci numarasıyla `users` koleksiyonunda arama yapar. Bulamazsa `null`
  /// döner — "Üye bulunamadı" mesajı bu sonuca göre gösterilir.
  Future<ClubMember?> findStudentByNumber(String studentId) async {
    try {
      final snap = await _db
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      return ClubMember(
        uid: doc.id,
        name: doc.data()['name'] as String? ?? '',
        studentId: doc.data()['studentId'] as String? ?? '',
      );
    } on FirebaseException catch (e) {
      throw Exception('Öğrenci aranamadı: ${e.message}');
    }
  }

  Future<void> addClubMember(String clubId, ClubMember member) async {
    try {
      final batch = _db.batch();

      batch.set(
        _db.collection('clubs').doc(clubId).collection('members').doc(
          member.uid,
        ),
        {
          'uid': member.uid,
          'name': member.name,
          'studentId': member.studentId,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.update(_db.collection('clubs').doc(clubId), {
        'adminUids': FieldValue.arrayUnion([member.uid]),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Üye eklenemedi: ${e.message}');
    }
  }

  Future<void> removeClubMember(String clubId, String uid) async {
    try {
      final batch = _db.batch();

      batch.delete(
        _db.collection('clubs').doc(clubId).collection('members').doc(uid),
      );
      batch.update(_db.collection('clubs').doc(clubId), {
        'adminUids': FieldValue.arrayRemove([uid]),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Üye çıkarılamadı: ${e.message}');
    }
  }

  CollectionReference<Map<String, dynamic>> _attendanceCollection(
    String clubId,
    String eventId,
  ) => _db
      .collection('clubs')
      .doc(clubId)
      .collection('club-events')
      .doc(eventId)
      .collection('attendance');

  Stream<List<AttendanceRecord>> getEventAttendance({
    required String clubId,
    required String eventId,
  }) {
    return _attendanceCollection(clubId, eventId)
        .orderBy('checkedInAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AttendanceRecord.fromJson(d.data()))
              .toList(),
        );
  }

  /// Aynı öğrencinin daha önce okutulup okutulmadığını kontrol eder — doküman
  /// id'si öğrencinin uid'i olduğu için tek bir `get()` yeterli.
  Future<AttendanceRecord?> getAttendanceRecord({
    required String clubId,
    required String eventId,
    required String uid,
  }) async {
    try {
      final doc = await _attendanceCollection(clubId, eventId).doc(uid).get();
      if (!doc.exists) return null;
      return AttendanceRecord.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Yoklama kontrol edilemedi: ${e.message}');
    }
  }

  Future<void> recordAttendance({
    required String clubId,
    required String eventId,
    required AttendanceRecord record,
  }) async {
    try {
      await _attendanceCollection(clubId, eventId).doc(record.uid).set({
        'uid': record.uid,
        'name': record.name,
        'studentId': record.studentId,
        'recordedBy': record.recordedBy,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Yoklama kaydedilemedi: ${e.message}');
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
      throw Exception('Topluluk takipten cikilamadi: ${e.message}');
    }
  }
}
