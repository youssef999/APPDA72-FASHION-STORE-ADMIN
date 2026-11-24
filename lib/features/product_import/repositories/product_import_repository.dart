import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/categories_repository.dart';
import '../../products/models/product_model.dart';

class ImportContext {
  final List<CategoryModel> categories;

  /// productid → Firestore document id of products already in the store.
  final Map<String, String> existing;

  const ImportContext(this.categories, this.existing);
}

class ProductImportRepository {
  static const int batchSize = 450;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection(FirestoreCollections.products);

  Future<ImportContext> loadContext() async {
    final results = await Future.wait([
      CategoriesRepository().watchCategories().first,
      _products.get(),
    ]);
    final categories = results[0] as List<CategoryModel>;
    final snapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    return ImportContext(categories, {
      for (final doc in snapshot.docs) '${doc.data()['productid'] ?? doc.id}': doc.id,
    });
  }

  /// New products get `rate: 0` and `date`; updates leave rating, date and size guide untouched.
  Future<void> save(
    List<ProductModel> products,
    Map<String, String> existing, {
    void Function(int done)? onProgress,
  }) async {
    var done = 0;
    for (var start = 0; start < products.length; start += batchSize) {
      final batch = _db.batch();
      final slice = products.skip(start).take(batchSize);
      for (final product in slice) {
        final docId = existing[product.productId];
        final ref = _products.doc(docId ?? product.productId);
        batch.set(
          ref,
          {
            ...product.toMap(),
            if (docId == null) 'rate': 0,
            if (docId == null) 'date': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      done += slice.length;
      onProgress?.call(done);
    }
  }
}
