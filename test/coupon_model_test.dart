import 'package:flutter_test/flutter_test.dart';
import 'package:thehatch_admin/features/coupons/models/coupon_model.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);
  final nextWeek = now.add(const Duration(days: 7));

  CouponModel coupon({
    String type = CouponModel.percent,
    num value = 20,
    DateTime? expiresAt,
    String target = CouponModel.targetAll,
    bool active = true,
    List<String> usedBy = const [],
  }) =>
      CouponModel(
        code: 'SUMMER20',
        type: type,
        value: value,
        expiresAt: expiresAt ?? nextWeek,
        target: target,
        active: active,
        usedBy: usedBy,
      );

  group('discountFor', () {
    test('percent of the subtotal', () => expect(coupon(value: 20).discountFor(250), 50));
    test('fixed amount', () => expect(coupon(type: CouponModel.fixed, value: 30).discountFor(250), 30));
    test('never more than the subtotal', () {
      expect(coupon(type: CouponModel.fixed, value: 500).discountFor(120), 120);
      expect(coupon(value: 100).discountFor(80), 80);
    });
    test('nothing on an empty cart', () => expect(coupon().discountFor(0), 0));
  });

  group('status', () {
    test('active before expiry', () => expect(coupon().statusAt(now), CouponStatus.active));
    test('expired after expiry', () => expect(coupon(expiresAt: now).statusAt(now), CouponStatus.expired));
    test('disabled wins', () => expect(coupon(active: false).statusAt(now), CouponStatus.disabled));
    test('a personal coupon is finished after one use', () {
      expect(coupon(target: 'u1', usedBy: ['u1']).statusAt(now), CouponStatus.used);
    });
    test('a public coupon stays open after other customers use it', () {
      final c = coupon(usedBy: ['u1', 'u2']);
      expect(c.statusAt(now), CouponStatus.active);
      expect(c.usedByUser('u1'), isTrue);
      expect(c.usedByUser('u3'), isFalse);
      expect(c.usedCount, 2);
    });
  });
}
