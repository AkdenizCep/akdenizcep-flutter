import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_event.dart';

class StudentEventsService {
  final _db = FirebaseFirestore.instance;

  Stream<List<StudentEvent>> getEvents() {
    return _db
        .collection('student-events')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => StudentEvent.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<StudentEvent> getEvent(String eventId) {
    return _db
        .collection('student-events')
        .doc(eventId)
        .snapshots()
        .map((snap) => StudentEvent.fromJson(snap.data()!..['id'] = snap.id));
  }

  Future<void> createEvent({
    required String authorUid,
    required String authorName,
    required String title,
    required DateTime date,
    required String location,
    required double locationLatitude,
    required double locationLongitude,
    required String description,
    String category = '',
    String imageUrl = '',
    int? capacity,
  }) async {
    try {
      await _db.collection('student-events').add({
        'authorUid': authorUid,
        'authorName': authorName,
        'title': title,
        'date': Timestamp.fromDate(date),
        'location': location,
        'locationLatitude': locationLatitude,
        'locationLongitude': locationLongitude,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'capacity': capacity,
        // Etkinliği paylaşan kişi otomatik olarak katılımcıdır.
        'attendeeIds': [authorUid],
        'attendeeCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Etkinlik olusturulamadi: ${e.message}');
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required String authorUid,
    required Map<String, dynamic> data,
  }) async {
    try {
      final doc = await _db.collection('student-events').doc(eventId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu etkinligi duzenleme yetkiniz yok.');
      }
      await _db.collection('student-events').doc(eventId).update(data);
    } on FirebaseException catch (e) {
      throw Exception('Etkinlik guncellenemedi: ${e.message}');
    }
  }

  Future<void> deleteEvent({
    required String eventId,
    required String authorUid,
  }) async {
    try {
      final doc = await _db.collection('student-events').doc(eventId).get();
      if (doc.data()?['authorUid'] != authorUid) {
        throw Exception('Bu etkinligi silme yetkiniz yok.');
      }
      await _db.collection('student-events').doc(eventId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Etkinlik silinemedi: ${e.message}');
    }
  }
}
