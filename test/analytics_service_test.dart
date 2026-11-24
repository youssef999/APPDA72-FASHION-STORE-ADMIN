import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thehatch_admin/features/analytics/models/analytics_report.dart';
import 'package:thehatch_admin/features/analytics/services/analytics_service.dart';
import 'package:thehatch_admin/features/orders/models/order_model.dart';
import 'package:thehatch_admin/features/products/models/product_model.dart';

void main() {
  final now = DateTime(2026, 11, 12, 15);

  OrderModel order(String id, DateTime at, num total, String status, {String size = 'M'}) => OrderModel.fromMap(id, {
        'order_id': id,
        'status': status,
        'finalTotal': total,
        'createdAt': Timestamp.fromDate(at),
        'order': [
          {'productid': 'p1', 'name': 'Top', 'nameAr': 'توب', 'price': total, 'quant': 1, 'size': size, 'colorAr': 'أسود'},
        ],
      });

  final product = ProductModel.fromMap('p1', {'productid': 'p1', 'name': 'Top', 'cat': 'Tops', 'catAr': 'توبات', 'quant': 2});

  test('revenue excludes refused orders and compares with the previous period', () {
    final report = AnalyticsService.build(
      orders: [
        order('1', now, 300, OrderStatus.delivered),
        order('2', now.subtract(const Duration(days: 2)), 200, OrderStatus.waiting, size: 'S'),
        order('3', now.subtract(const Duration(days: 1)), 999, OrderStatus.refused),
        order('4', now.subtract(const Duration(days: 10)), 250, OrderStatus.delivered),
      ],
      products: [product],
      users: const [],
      from: now.subtract(const Duration(days: 6)),
      to: now,
    );

    expect(report.current.revenue, 500);
    expect(report.current.orders, 2);
    expect(report.current.averageOrder, 250);
    expect(report.current.refusalRate, closeTo(1 / 3, 1e-9));
    expect(report.previous.revenue, 250);
    expect(AnalyticsReport.change(report.current.revenue, report.previous.revenue), 100);
    expect(report.bucket, AnalyticsBucket.day);
    expect(report.series, hasLength(7));
    expect(report.series.fold<num>(0, (s, p) => s + p.revenue), 500);
    expect(report.categoryRevenue, {'توبات': 500});
    expect(report.sizeUnits.keys.toList(), containsAll(['M', 'S']));
    expect(report.topProducts.single.units, 2);
    expect(report.lowStock.single.productId, 'p1');
    expect(report.noSales, isEmpty);
  });
}
