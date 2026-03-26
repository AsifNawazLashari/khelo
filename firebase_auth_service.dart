// lib/data/datasources/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_config.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        managedTournaments: [],
        managedTeams: [],
      );

      await _firestore
          .collection(FirestorePaths.users)
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthFailure(message: e.toString());
    }
  }

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore
          .collection(FirestorePaths.users)
          .doc(credential.user!.uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        throw const AuthFailure(message: 'User profile not found');
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthFailure(message: 'Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();

      if (!doc.exists) {
        final newUser = UserModel(
          uid: uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? 'User',
          role: 'player',
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          managedTournaments: [],
          managedTeams: [],
        );
        await _firestore
            .collection(FirestorePaths.users)
            .doc(uid)
            .set(newUser.toFirestore());
        return newUser;
      } else {
        await _firestore.collection(FirestorePaths.users).doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return UserModel.fromFirestore(doc);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(message: _mapAuthErrorMessage(e.code), code: e.code);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure(message: e.toString());
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(message: _mapAuthErrorMessage(e.code), code: e.code);
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .update({'role': role});
  }

  String _mapAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
