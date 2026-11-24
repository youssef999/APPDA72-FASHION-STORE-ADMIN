import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/formatters.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/repositories/notifications_repository.dart';
import '../models/coupon_model.dart';

class CouponsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationsRepository _notifications = NotificationsRepository();

  CollectionReference<Map<String, dynamic>> get _coupons => _db.collection(FirestoreCollections.coupons);

  /// Newest first.
  Stream<List<CouponModel>> watchCoupons() => _coupons.snapshots().map((snap) {
        final list = snap.docs.map((d) => CouponModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        return list;
      });

  /// The code is the document id, so the transaction refuses a code that already exists.
  /// The customer(s) are told about the coupon through a notification in the same commit.
  Future<void> create(CouponModel coupon) async {
    final ref = _coupons.doc(coupon.code);
    await _db.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) throw 'الكود ${coupon.code} مستخدم بالفعل';
      tx.set(ref, coupon.toMap());
      tx.set(_notifications.newDoc(), _announcement(coupon).toMap());
    });
  }

  Future<void> setActive(String code, bool active) => _coupons.doc(code).update({'active': active});

  Future<void> delete(String code) => _coupons.doc(code).delete();

  NotificationModel _announcement(CouponModel coupon) {
    final expiry = Formatters.date(coupon.expiresAt);
    return NotificationModel(
      title: 'A gift for you: ${coupon.valueLabel} off',
      titleAr: 'هدية لك: خصم ${coupon.valueLabel}',
      body: 'Use code ${coupon.code} at checkout before $expiry.',
      bodyAr: 'استخدم الكود ${coupon.code} عند إتمام الطلب قبل $expiry.',
      target: coupon.target,
      targetEmail: coupon.targetEmail,
      type: 'coupon',
    );
  }
}
