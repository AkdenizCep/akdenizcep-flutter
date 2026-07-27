import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static const _allowedDomain = 'ogr.akdeniz.edu.tr';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// authStateChanges()'den farkli olarak reload() gibi profil
  /// guncellemelerinde de (emailVerified degisimi dahil) yeni deger yayar.
  Stream<User?> userChanges() => _auth.userChanges();

  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
  }) async {
    _validateEmailDomain(email);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'studentId': studentId,
        'followedClubs': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await credential.user!.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    _validateEmailDomain(email);

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    _validateEmailDomain(email);

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  void _validateEmailDomain(String email) {
    final domain = email.split('@').last;
    if (domain != _allowedDomain) {
      throw Exception(
        'Yalnizca @$_allowedDomain uzantili e-posta adresleri kabul edilir.',
      );
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullaniliyor.';
      case 'invalid-email':
        return 'Gecersiz e-posta adresi.';
      case 'weak-password':
        return 'Sifre cok zayif.';
      case 'user-not-found':
        return 'Bu e-posta ile kayitli kullanici bulunamadi.';
      case 'wrong-password':
        return 'Hatali sifre.';
      case 'too-many-requests':
        return 'Cok fazla istek gonderildi. Lutfen birkac dakika sonra tekrar deneyin.';
      default:
        return 'Bir hata olustu. Lutfen tekrar deneyin.';
    }
  }
}
