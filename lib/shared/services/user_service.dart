import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_summary.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<UserProfileSummary?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfileSummary.fromJson(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }
}
