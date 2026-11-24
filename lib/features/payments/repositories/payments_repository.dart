import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_config_model.dart';

class PaymentsRepository {
  final FirebaseFirestore _db;

  PaymentsRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _configRef =>
      _db.collection(PaymentConfigModel.collection).doc(PaymentConfigModel.docId);

  DocumentReference<Map<String, dynamic>> get _secretsRef =>
      _db.collection(PaymentSecretsModel.collection).doc(PaymentSecretsModel.docId);

  Future<PaymentConfigModel> fetchConfig() async {
    final snap = await _configRef.get();
    return PaymentConfigModel.fromMap(snap.data());
  }

  Future<PaymentSecretsModel> fetchSecrets() async {
    final snap = await _secretsRef.get();
    return PaymentSecretsModel.fromMap(snap.data());
  }

  Future<void> saveConfig(PaymentConfigModel model) async {
    await _configRef.set({
      ...model.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveSecrets(PaymentSecretsModel model) async {
    await _secretsRef.set({
      ...model.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
