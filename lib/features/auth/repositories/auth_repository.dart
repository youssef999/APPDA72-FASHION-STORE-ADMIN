import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Waits for Firebase to restore the persisted web session.
  Future<User?> restoreSession() => _auth.authStateChanges().first;

  Future<User> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    return credential.user!;
  }

  /// An account is an admin when `admins/{lowercase email}` exists.
  Future<bool> isAdmin(User user) async {
    final email = (user.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return false;
    final doc = await _db.collection(FirestoreCollections.admins).doc(email).get();
    return doc.exists;
  }

  Future<void> signOut() => _auth.signOut();
}
