import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/repositories/notifications_repository.dart';

/// When admin restocks a size, notifies active waitlist subscribers via inbox docs.
class StockWaitlistNotifier {
  StockWaitlistNotifier._();

  static final _db = FirebaseFirestore.instance;
  static final _notifications = NotificationsRepository();

  static Future<void> notifyRestocked({
    required String productId,
    required String productName,
    required String productNameAr,
    required Map<String, num> previousStock,
    required Map<String, num> nextStock,
  }) async {
    if (productId.isEmpty) return;
    final restockedSizes = <String>[];
    for (final entry in nextStock.entries) {
      final prev = previousStock[entry.key] ?? 0;
      if (prev <= 0 && entry.value > 0) restockedSizes.add(entry.key);
    }
    if (restockedSizes.isEmpty) return;

    for (final size in restockedSizes) {
      final snap = await _db
          .collection(FirestoreCollections.stockWaitlist)
          .where('productId', isEqualTo: productId)
          .where('size', isEqualTo: size)
          .where('active', isEqualTo: true)
          .limit(40)
          .get();
      if (snap.docs.isEmpty) continue;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        final uid = '${doc.data()['uid'] ?? ''}';
        if (uid.isEmpty) continue;
        _notifications.addToBatch(
          batch,
          NotificationModel(
            title: 'Back in stock',
            titleAr: 'رجعت للمخزون',
            body: '$productName · size $size is available again',
            bodyAr: '$productNameAr · المقاس $size متاح من جديد',
            target: uid,
            type: 'back_in_stock',
            productId: productId,
            size: size,
          ),
        );
        batch.update(doc.reference, {
          'active': false,
          'notifiedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
