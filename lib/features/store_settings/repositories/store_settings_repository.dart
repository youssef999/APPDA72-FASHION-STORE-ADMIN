import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';

/// Merchant-facing store ops: commerce thresholds, delivery fee, WhatsApp.
class StoreSettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _commerce =>
      _db.collection(FirestoreCollections.config).doc(FirestoreCollections.configCommerce);

  DocumentReference<Map<String, dynamic>> get _app =>
      _db.collection(FirestoreCollections.config).doc(FirestoreCollections.configApp);

  DocumentReference<Map<String, dynamic>> get _delivery =>
      _db.collection(FirestoreCollections.delivery).doc(FirestoreCollections.deliveryMainDoc);

  Future<StoreSettingsSnapshot> fetch() async {
    final results = await Future.wait([_commerce.get(), _app.get(), _delivery.get()]);
    return StoreSettingsSnapshot(
      commerce: results[0].data() ?? const {},
      app: results[1].data() ?? const {},
      delivery: results[2].data() ?? const {},
    );
  }

  Future<void> save({
    required double freeShippingMin,
    required double vipGiftMin,
    required int vipOrdersRequired,
    required double deliveryFee,
    required String whatsappPhone,
  }) async {
    final batch = _db.batch();
    batch.set(
      _commerce,
      {
        'freeShippingMin': freeShippingMin,
        'vipGiftMin': vipGiftMin,
        'vipOrdersRequired': vipOrdersRequired,
        'currency': 'ر.س',
        'currencyCode': 'SAR',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _app,
      {
        'whatsappPhone': whatsappPhone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _delivery,
      {
        'del': deliveryFee,
        'currencyCode': 'SAR',
        'label': 'رسوم التوصيل',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}

class StoreSettingsSnapshot {
  final Map<String, dynamic> commerce;
  final Map<String, dynamic> app;
  final Map<String, dynamic> delivery;

  const StoreSettingsSnapshot({
    required this.commerce,
    required this.app,
    required this.delivery,
  });
}
