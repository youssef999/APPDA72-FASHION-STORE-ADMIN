import 'package:cloud_firestore/cloud_firestore.dart';

/// Public store flags under `config/app` (WhatsApp phone, push, …).
class StoreAppConfigRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('config').doc('app');

  Future<Map<String, dynamic>> fetch() async {
    final snap = await _doc.get();
    return snap.data() ?? <String, dynamic>{};
  }

  Stream<Map<String, dynamic>> watch() =>
      _doc.snapshots().map((snap) => snap.data() ?? <String, dynamic>{});

  Future<void> saveWhatsAppPhone(String phone) async {
    await _doc.set({
      'whatsappPhone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
