import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories => _db.collection(FirestoreCollections.categories);
  CollectionReference<Map<String, dynamic>> get _products => _db.collection(FirestoreCollections.products);

  Stream<List<CategoryModel>> watchCategories() => _categories.snapshots().map((snap) {
        final list = snap.docs.map((d) => CategoryModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => (a.order ?? 1 << 30).compareTo(b.order ?? 1 << 30));
        return list;
      });

  /// Products link to a category by its English `name`, so a rename is applied to them too.
  Future<void> save(CategoryModel category, {CategoryModel? previous}) async {
    final ref = category.docId.isEmpty ? _categories.doc() : _categories.doc(category.docId);
    final batch = _db.batch();
    batch.set(ref, category.toMap(ref.id), SetOptions(merge: true));

    if (previous != null && (previous.name != category.name || previous.nameAr != category.nameAr)) {
      final linked = await _products.where('cat', isEqualTo: previous.name).get();
      for (final doc in linked.docs) {
        batch.update(doc.reference, {'cat': category.name, 'catAr': category.nameAr});
      }
    }
    await batch.commit();
  }

  Future<int> productCount(String categoryName) async {
    final result = await _products.where('cat', isEqualTo: categoryName).count().get();
    return result.count ?? 0;
  }

  Future<void> delete(String docId) => _categories.doc(docId).delete();
}
