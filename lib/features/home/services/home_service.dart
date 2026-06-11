import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';
import '../models/home_event.dart';

class HomeService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Announcement>> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Announcement.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Stream<List<HomeEvent>> getUpcomingEvents() {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('student-events')
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date', descending: false)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => HomeEvent.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }
}
