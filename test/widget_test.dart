import 'package:flutter_test/flutter_test.dart';
import 'package:thehatch_admin/features/notifications/models/notification_model.dart';
import 'package:thehatch_admin/features/orders/models/order_model.dart';

void main() {
  test('reads an order written by the store app', () {
    final order = OrderModel.fromMap('doc1', {
      'order_id': '1234',
      'status': 'del',
      'user_uid': 'u1',
      'user_email': 'a@b.com',
      'total': 200,
      'del': 30,
      'order': [
        {'productid': 'p1', 'name': 'Shirt', 'price': 100, 'quant': 2, 'size': 'M'},
      ],
    });
    expect(order.orderId, '1234');
    expect(order.status, OrderStatus.delivered);
    expect(order.finalTotal, 230);
    expect(order.itemCount, 2);
    expect(order.items.single.size, 'M');
  });

  test('a notification is a broadcast only without a specific recipient', () {
    const broadcast = NotificationModel(title: 't', titleAr: 't', body: 'b', bodyAr: 'b');
    const personal = NotificationModel(title: 't', titleAr: 't', body: 'b', bodyAr: 'b', target: 'u1', targetEmail: 'a@b.com');
    expect(broadcast.isBroadcast, isTrue);
    expect(personal.isBroadcast, isFalse);
    expect(personal.toMap()['target'], 'u1');
  });
}
