import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';

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
}
