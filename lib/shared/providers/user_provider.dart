import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/app_user.dart';
import '../models/user_profile_summary.dart';
import '../services/user_service.dart';

final firebaseAuthProvider = Provider((_) => FirebaseAuth.instance);

Future<void> signOut() => FirebaseAuth.instance.signOut();

Future<void> sendPasswordResetEmail(String email) =>
    FirebaseAuth.instance.sendPasswordResetEmail(email: email);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return null;
            return AppUser.fromJson(snap.data()!..['id'] = snap.id);
          });
    },
    loading: () => Stream.value(null),
    error: (e, st) => Stream.value(null),
  );
});

final userServiceProvider = Provider((_) => UserService());

final userProfileProvider =
    FutureProvider.family<UserProfileSummary?, String>((ref, uid) async {
  if (uid.isEmpty) return null;

  final currentUser = ref.watch(currentUserProvider).valueOrNull ??
      await ref.watch(currentUserProvider.future);
  if (currentUser != null && currentUser.id == uid) {
    return UserProfileSummary(
      uid: currentUser.id,
      name: currentUser.name,
      photoUrl: currentUser.photoUrl,
    );
  }

  return ref.watch(userServiceProvider).getUserProfile(uid);
});

