import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/notification_model.dart';

/// Notifications are Firestore documents the store app listens to and shows locally.
class NotificationsRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.notifications);

  Stream<List<NotificationModel>> watchLatest({int limit = 100}) => _collection
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => NotificationModel.fromMap(d.id, d.data())).toList());

  Future<void> send(NotificationModel notification) => _collection.add(notification.toMap());

  /// Same document as [send], for use inside a batch that also updates the order.
  void addToBatch(WriteBatch batch, NotificationModel notification) =>
      batch.set(_collection.doc(), notification.toMap());

  /// A fresh reference for writes inside a transaction.
  DocumentReference<Map<String, dynamic>> newDoc() => _collection.doc();

  Future<void> delete(String id) => _collection.doc(id).delete();
}
