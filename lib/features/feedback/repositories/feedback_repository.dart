import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(FirestoreCollections.feedback);

  Stream<List<FeedbackModel>> watchAll() => _col.snapshots().map((snap) {
        final list = snap.docs.map((d) => FeedbackModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        return list;
      });

  Future<void> updateStatus({
    required String id,
    required String status,
    String? adminNote,
  }) {
    return _col.doc(id).update({
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
