import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/repositories/notifications_repository.dart';
import '../models/order_model.dart';

class OrdersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationsRepository _notifications = NotificationsRepository();

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection(FirestoreCollections.orders);

  /// Newest first; legacy orders without `createdAt` fall back to their date strings.
  Stream<List<OrderModel>> watchOrders() => _orders.snapshots().map((snap) {
        final orders = snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
        orders.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        return orders;
      });

  /// Updates the status and queues a notification for the customer in one batch.
  Future<void> updateStatus(OrderModel order, String status) async {
    final batch = _db.batch();
    batch.update(_orders.doc(order.docId), {
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
    if (order.userUid.isNotEmpty || order.userEmail.isNotEmpty) {
      _notifications.addToBatch(batch, _statusNotification(order, status));
    }
    await batch.commit();
    if (status == OrderStatus.refused) {
      await _restock(order);
      await _releaseCoupon(order);
    }
  }

  /// A refused order gives the customer their coupon back; a deleted coupon is simply skipped.
  Future<void> _releaseCoupon(OrderModel order) async {
    if (order.couponCode.isEmpty || order.userUid.isEmpty) return;
    final ref = _db.collection(FirestoreCollections.coupons).doc(order.couponCode);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final usedBy = List<String>.from(snap.data()?['usedBy'] as List? ?? const []);
      if (!snap.exists || !usedBy.remove(order.userUid)) return;
      tx.update(ref, {'usedBy': usedBy, 'usedCount': usedBy.length});
    });
  }

  /// Puts refused items back into their size stock and the product total.
  Future<void> _restock(OrderModel order) async {
    for (final item in order.items) {
      if (item.productId.isEmpty || item.quantity <= 0) continue;
      final query = await _db
          .collection(FirestoreCollections.products)
          .where('productid', isEqualTo: item.productId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) continue;
      final ref = query.docs.first.reference;
      await _db.runTransaction((tx) async {
        final data = (await tx.get(ref)).data() ?? {};
        final Map<String, dynamic> changes = {'quant': ((data['quant'] ?? 0) as num) + item.quantity};
        // Only touch stock when the map already covers every size — never grow a partial map.
        if (item.size.isNotEmpty && data['stock'] is Map) {
          final sizes = data['sizes'] is List
              ? (data['sizes'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
              : const <String>[];
          final stock = <String, num>{
            for (final e in (data['stock'] as Map).entries)
              '${e.key}': e.value is num ? e.value as num : num.tryParse('${e.value}') ?? 0,
          };
          if (sizes.isNotEmpty && sizes.every(stock.containsKey)) {
            stock[item.size] = (stock[item.size] ?? 0) + item.quantity;
            changes['stock'] = stock;
            changes['quant'] = stock.values.fold<num>(0, (sum, qty) => sum + qty);
          }
        }
        final num sold = ((data['soldCount'] ?? 0) as num) - item.quantity;
        changes['soldCount'] = sold < 0 ? 0 : sold;
        tx.update(ref, changes);
      });
    }
  }

  NotificationModel _statusNotification(OrderModel order, String status) {
    final (String en, String ar) = switch (status) {
      OrderStatus.approved => ('Your order is being prepared', 'طلبك قيد التجهيز الآن'),
      OrderStatus.delivered => ('Your order has been delivered', 'تم توصيل طلبك، نتمنى أن ينال إعجابك'),
      OrderStatus.refused => ('Your order was declined', 'نعتذر، تم رفض طلبك'),
      _ => ('Your order is under review', 'طلبك قيد المراجعة'),
    };
    return NotificationModel(
      title: 'Order #${order.orderId}',
      titleAr: 'طلب رقم ${order.orderId}',
      body: en,
      bodyAr: ar,
      target: order.userUid.isNotEmpty ? order.userUid : NotificationModel.targetAll,
      targetEmail: order.userEmail,
      type: 'order_status',
      orderId: order.orderId,
    );
  }
}
