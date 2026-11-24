import '../../orders/models/order_model.dart';
import '../../products/models/product_model.dart';
import '../../users/models/user_model.dart';
import '../models/analytics_report.dart';

/// Pure calculations over the loaded collections; shared by the dashboard and the analytics page.
class AnalyticsService {
  AnalyticsService._();

  static const int lowStockLimit = 3;

  static AnalyticsReport build({
    required List<OrderModel> orders,
    required List<ProductModel> products,
    required List<UserModel> users,
    required DateTime from,
    required DateTime to,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final length = end.difference(start);
    final previousStart = start.subtract(length);

    final dated = orders.where((o) => o.createdAt != null).toList();
    final inRange = dated.where((o) => _within(o.createdAt!, start, end)).toList();
    final inPrevious = dated.where((o) => _within(o.createdAt!, previousStart, start)).toList();
    final sold = inRange.where((o) => o.status != OrderStatus.refused).toList();

    final bucket = length.inDays <= 31
        ? AnalyticsBucket.day
        : length.inDays <= 120
            ? AnalyticsBucket.week
            : AnalyticsBucket.month;

    final productsById = {for (final p in products) p.productId: p};
    final categoryRevenue = <String, num>{};
    final sizeUnits = <String, num>{};
    final colorUnits = <String, num>{};
    final productTotals = <String, ProductSales>{};
    final weekday = List<int>.filled(7, 0);
    final hours = List<int>.filled(24, 0);

    for (final order in sold) {
      weekday[order.createdAt!.weekday % 7]++;
      hours[order.createdAt!.hour]++;
      for (final item in order.items) {
        final product = productsById[item.productId];
        final category = product == null ? 'غير معروف' : (product.catAr.isNotEmpty ? product.catAr : product.cat);
        _add(categoryRevenue, category, item.lineTotal);
        if (item.size.isNotEmpty) _add(sizeUnits, item.size, item.quantity);
        final color = item.colorAr.isNotEmpty ? item.colorAr : item.color;
        if (color.isNotEmpty) _add(colorUnits, color, item.quantity);
        final key = item.productId.isEmpty ? item.name : item.productId;
        final prev = productTotals[key];
        productTotals[key] = ProductSales(
          productId: item.productId,
          name: item.displayName,
          image: product?.image ?? item.image,
          units: (prev?.units ?? 0) + item.quantity,
          revenue: (prev?.revenue ?? 0) + item.lineTotal,
        );
      }
    }

    final soldIds = productTotals.values.map((p) => p.productId).toSet();
    final byRevenue = productTotals.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
    final byUnits = productTotals.values.toList()..sort((a, b) => b.units.compareTo(a.units));
    return AnalyticsReport(
      from: start,
      to: end.subtract(const Duration(days: 1)),
      bucket: bucket,
      current: _kpis(inRange, users, start, end),
      previous: _kpis(inPrevious, users, previousStart, start),
      series: _series(sold, start, end, bucket),
      statusCounts: {for (final s in OrderStatus.all) s: inRange.where((o) => o.status == s).length},
      categoryRevenue: _sorted(categoryRevenue),
      sizeUnits: _sorted(sizeUnits),
      colorUnits: _sorted(colorUnits),
      weekdayOrders: weekday,
      hourOrders: hours,
      topProducts: byRevenue.take(10).toList(),
      soldProducts: byUnits,
      lowStock: (products.where((p) => p.quant <= lowStockLimit).toList()..sort((a, b) => a.quant.compareTo(b.quant))),
      noSales: products.where((p) => !soldIds.contains(p.productId) && p.quant > 0).toList(),
    );
  }

  static AnalyticsKpis _kpis(List<OrderModel> orders, List<UserModel> users, DateTime start, DateTime end) {
    final sold = orders.where((o) => o.status != OrderStatus.refused);
    return AnalyticsKpis(
      revenue: sold.fold<num>(0, (sum, o) => sum + o.finalTotal),
      orders: sold.length,
      units: sold.fold<num>(0, (sum, o) => sum + o.itemCount),
      refused: orders.length - sold.length,
      newUsers: users.where((u) => u.createdAt != null && _within(u.createdAt!, start, end)).length,
    );
  }

  static List<SeriesPoint> _series(List<OrderModel> orders, DateTime start, DateTime end, AnalyticsBucket bucket) {
    final points = <SeriesPoint>[];
    var cursor = _bucketStart(start, bucket);
    while (cursor.isBefore(end)) {
      final next = _next(cursor, bucket);
      final slice = orders.where((o) => _within(o.createdAt!, cursor, next));
      points.add(SeriesPoint(cursor, slice.fold<num>(0, (sum, o) => sum + o.finalTotal), slice.length));
      cursor = next;
    }
    return points;
  }

  static DateTime _bucketStart(DateTime date, AnalyticsBucket bucket) => switch (bucket) {
        AnalyticsBucket.day => date,
        AnalyticsBucket.week => date.subtract(Duration(days: date.weekday % 7)),
        AnalyticsBucket.month => DateTime(date.year, date.month),
      };

  static DateTime _next(DateTime date, AnalyticsBucket bucket) => switch (bucket) {
        AnalyticsBucket.day => DateTime(date.year, date.month, date.day + 1),
        AnalyticsBucket.week => DateTime(date.year, date.month, date.day + 7),
        AnalyticsBucket.month => DateTime(date.year, date.month + 1),
      };

  static bool _within(DateTime date, DateTime start, DateTime end) => !date.isBefore(start) && date.isBefore(end);

  static void _add(Map<String, num> map, String key, num value) => map[key] = (map[key] ?? 0) + value;

  static Map<String, num> _sorted(Map<String, num> map) =>
      Map.fromEntries(map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
}
