import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branding_model.dart';

class BrandingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection(BrandingModel.collection).doc(BrandingModel.docId);

  Stream<BrandingModel> watch() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return BrandingModel.defaults();
      return BrandingModel.fromMap(snap.data());
    });
  }

  Future<BrandingModel> fetch() async {
    final snap = await _doc.get();
    if (!snap.exists || snap.data() == null) return BrandingModel.defaults();
    return BrandingModel.fromMap(snap.data());
  }

  Future<void> save(BrandingModel model) async {
    await _doc.set({
      ...model.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
