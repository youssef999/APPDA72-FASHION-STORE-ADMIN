import '../../products/models/product_model.dart';

enum AnalyticsBucket { day, week, month }

class AnalyticsKpis {
  final num revenue;
  final int orders;
  final num units;
  final int refused;
  final int newUsers;

  const AnalyticsKpis({
    required this.revenue,
    required this.orders,
    required this.units,
    required this.refused,
    required this.newUsers,
  });

  num get averageOrder => orders == 0 ? 0 : revenue / orders;

  /// Share of all orders in the period (including refused ones) that were refused.
  double get refusalRate => orders + refused == 0 ? 0 : refused / (orders + refused);
}

class SeriesPoint {
  final DateTime start;
  final num revenue;
  final int orders;

  const SeriesPoint(this.start, this.revenue, this.orders);
}

class ProductSales {
  final String productId;
  final String name;
  final String image;
  final num units;
  final num revenue;

  const ProductSales({
    required this.productId,
    required this.name,
    required this.image,
    required this.units,
    required this.revenue,
  });
}

class AnalyticsReport {
  final DateTime from;
  final DateTime to;
  final AnalyticsBucket bucket;
  final AnalyticsKpis current;
  final AnalyticsKpis previous;
  final List<SeriesPoint> series;
  final Map<String, int> statusCounts;
  final Map<String, num> categoryRevenue;
  final Map<String, num> sizeUnits;
  final Map<String, num> colorUnits;
  final List<int> weekdayOrders;
  final List<int> hourOrders;
  final List<ProductSales> topProducts;
  /// All products with sales in the period, sorted by units (desc).
  final List<ProductSales> soldProducts;
  final List<ProductModel> lowStock;
  final List<ProductModel> noSales;

  const AnalyticsReport({
    required this.from,
    required this.to,
    required this.bucket,
    required this.current,
    required this.previous,
    required this.series,
    required this.statusCounts,
    required this.categoryRevenue,
    required this.sizeUnits,
    required this.colorUnits,
    required this.weekdayOrders,
    required this.hourOrders,
    required this.topProducts,
    required this.soldProducts,
    required this.lowStock,
    required this.noSales,
  });

  /// Percentage change versus the previous period of the same length; null when there is no baseline.
  static double? change(num current, num previous) =>
      previous == 0 ? (current == 0 ? 0 : null) : (current - previous) / previous * 100;
}
