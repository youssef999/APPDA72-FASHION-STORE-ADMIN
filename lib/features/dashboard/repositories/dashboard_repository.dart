import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';

class DashboardCounts {
  final int products;
  final int lowStock;
  final int categories;
  final int users;

  const DashboardCounts({
    required this.products,
    required this.lowStock,
    required this.categories,
    required this.users,
  });
}

/// Server-side count queries, so the dashboard never downloads whole collections.
class DashboardRepository {
  static const int lowStockLimit = 3;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DashboardCounts> loadCounts() async {
    final products = _db.collection(FirestoreCollections.products);
    final results = await Future.wait([
      _count(products),
      _count(products.where('quant', isLessThanOrEqualTo: lowStockLimit)),
      _count(_db.collection(FirestoreCollections.categories)),
      _count(_db.collection(FirestoreCollections.users)),
    ]);
    return DashboardCounts(products: results[0], lowStock: results[1], categories: results[2], users: results[3]);
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async => (await query.count().get()).count ?? 0;
}
