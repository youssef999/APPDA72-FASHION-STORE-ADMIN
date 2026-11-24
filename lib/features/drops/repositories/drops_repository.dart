import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../products/repositories/products_repository.dart';
import '../models/drop_model.dart';

class DropsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProductsRepository _products = ProductsRepository();

  CollectionReference<Map<String, dynamic>> get _drops => _db.collection(FirestoreCollections.drops);

  Stream<List<DropModel>> watchDrops() => _drops.snapshots().map((snap) {
        final list = snap.docs.map((d) => DropModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => b.launchAt.compareTo(a.launchAt));
        return list;
      });

  Future<DropModel?> getById(String id) async {
    final doc = await _drops.doc(id).get();
    final data = doc.data();
    return data == null ? null : DropModel.fromMap(doc.id, data);
  }

  Future<void> save(DropModel drop) async {
    final isNew = drop.id.isEmpty;
    final ref = isNew ? _drops.doc() : _drops.doc(drop.id);
    await ref.set(drop.toMap(isNew: isNew), SetOptions(merge: true));
    await _syncProductFlags(ref.id, drop);
  }

  /// Writes dropId + visibleFrom onto linked products for faster client filtering later.
  Future<void> _syncProductFlags(String dropId, DropModel drop) async {
    final products = await _products.watchProducts().first;
    final batch = _db.batch();
    for (final product in products) {
      final linked = drop.productIds.contains(product.productId);
      final wasLinked = product.dropId == dropId;
      if (!linked && !wasLinked) continue;
      final ref = _db.collection(FirestoreCollections.products).doc(product.docId.isEmpty ? product.productId : product.docId);
      if (linked) {
        batch.set(
          ref,
          {
            'dropId': dropId,
            'visibleFrom': Timestamp.fromDate(drop.launchAt.toUtc()),
          },
          SetOptions(merge: true),
        );
      } else if (wasLinked) {
        batch.set(
          ref,
          {
            'dropId': '',
            'visibleFrom': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
  }

  Future<void> delete(String id) async {
    final drop = await getById(id);
    if (drop != null) {
      await _syncProductFlags(id, DropModel(
        id: id,
        title: drop.title,
        titleAr: drop.titleAr,
        launchAt: drop.launchAt,
        webUnlockAt: drop.webUnlockAt,
        productIds: const [],
        status: drop.status,
      ));
    }
    await _drops.doc(id).delete();
  }
}
