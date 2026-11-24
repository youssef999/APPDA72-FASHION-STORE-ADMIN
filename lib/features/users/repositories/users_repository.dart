import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/user_model.dart';

/// `Users/{uid}` documents are written by the store app on every sign-in.
class UsersRepository {
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection(FirestoreCollections.users);

  /// Most recently active first.
  Stream<List<UserModel>> watchUsers() => _users.snapshots().map((snap) {
        final users = snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList();
        DateTime activity(UserModel u) => u.lastLoginAt ?? u.createdAt ?? DateTime(2000);
        users.sort((a, b) => activity(b).compareTo(activity(a)));
        return users;
      });
}
