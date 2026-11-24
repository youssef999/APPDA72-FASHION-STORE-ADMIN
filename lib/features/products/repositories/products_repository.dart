import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final CollectionReference<Map<String, dynamic>> _products =
      FirebaseFirestore.instance.collection(FirestoreCollections.products);

  Stream<List<ProductModel>> watchProducts() => _products.snapshots().map(
        (snap) => snap.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList()..sort(_byDisplayOrder),
      );

  static int _byDisplayOrder(ProductModel a, ProductModel b) {
    final ao = a.order ?? 1 << 30;
    final bo = b.order ?? 1 << 30;
    if (ao != bo) return ao.compareTo(bo);
    final cat = a.cat.compareTo(b.cat);
    if (cat != 0) return cat;
    return a.name.compareTo(b.name);
  }

  Future<ProductModel?> getById(String docId) async {
    final doc = await _products.doc(docId).get();
    final data = doc.data();
    return data == null ? null : ProductModel.fromMap(doc.id, data);
  }

  /// New documents use the product id as their document id; `date` is only set on create.
  /// `rate` belongs to customers: it starts at 0 and the dashboard never overwrites it.
  Future<void> save(ProductModel product) async {
    final isNew = product.docId.isEmpty;
    final ref = _products.doc(isNew ? product.productId : product.docId);
    await ref.set({
      ...product.toMap(),
      if (isNew) ...{
        'date': DateTime.now().toIso8601String(),
        'rate': 0,
      },
    }, SetOptions(merge: true));
  }

  Future<bool> productIdExists(String productId) async {
    final query = await _products.where('productid', isEqualTo: productId).limit(1).get();
    return query.docs.isNotEmpty;
  }

  Future<void> delete(String docId) => _products.doc(docId).delete();

  Future<void> setBestSeller(String docId, bool isBestSeller) =>
      _products.doc(docId).update({'isBestSeller': isBestSeller});

  Future<void> updateDisplayOrder(String docId, int order) =>
      _products.doc(docId).set({'order': order}, SetOptions(merge: true));

  /// Persists 1-based display order for the given products (docId → order).
  Future<void> saveDisplayOrders(Map<String, int> ordersByDocId) async {
    if (ordersByDocId.isEmpty) return;
    WriteBatch? batch;
    var ops = 0;

    Future<void> flush() async {
      final b = batch;
      if (b == null || ops == 0) return;
      await b.commit();
      batch = null;
      ops = 0;
    }

    for (final entry in ordersByDocId.entries) {
      batch ??= FirebaseFirestore.instance.batch();
      batch!.set(_products.doc(entry.key), {'order': entry.value}, SetOptions(merge: true));
      ops++;
      if (ops >= 400) await flush();
    }
    await flush();
  }

  /// Aggregates sold quantities from non-refused orders: productId → qty.
  Future<Map<String, num>> loadSoldCountsFromOrders() async {
    final ordersSnap = await FirebaseFirestore.instance.collection(FirestoreCollections.orders).get();
    final totals = <String, num>{};

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      if ('${data['status']}' == 'refuse') continue;
      final items = data['order'];
      if (items is! List) continue;
      for (final raw in items) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final productId = '${map['productid'] ?? map['productId'] ?? map['product_id'] ?? ''}'.trim();
        if (productId.isEmpty) continue;
        final qty = map['quant'] ?? map['quantity'] ?? map['qty'];
        final num amount = qty is num ? qty : num.tryParse('$qty') ?? 0;
        if (amount <= 0) continue;
        totals[productId] = (totals[productId] ?? 0) + amount;
      }
    }
    return totals;
  }

  /// Rebuilds `soldCount` on every product from order history.
  Future<({int updated, int withSales})> recomputeSoldCountsFromOrders() async {
    final totals = await loadSoldCountsFromOrders();
    final productsSnap = await _products.get();
    var updated = 0;
    WriteBatch? batch;
    var ops = 0;

    Future<void> flush() async {
      final b = batch;
      if (b == null || ops == 0) return;
      await b.commit();
      batch = null;
      ops = 0;
    }

    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final productId = '${data['productid'] ?? doc.id}'.trim();
      final num next = totals[productId] ?? 0;
      final num current = data['soldCount'] is num
          ? data['soldCount'] as num
          : num.tryParse('${data['soldCount'] ?? ''}') ?? 0;
      if (current == next) continue;

      batch ??= FirebaseFirestore.instance.batch();
      // merge set so the field is created even if the doc shape is odd
      batch!.set(doc.reference, {'soldCount': next}, SetOptions(merge: true));
      ops++;
      updated++;
      if (ops >= 400) await flush();
    }
    await flush();
    return (updated: updated, withSales: totals.length);
  }
}
