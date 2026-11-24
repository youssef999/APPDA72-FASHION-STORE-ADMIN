import 'dart:async';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/categories_repository.dart';
import '../../products/models/product_model.dart';
import '../../products/repositories/products_repository.dart';

class ProductOrderController extends GetxController {
  static const String listId = 'product_order_list';

  final ProductsRepository _repo = ProductsRepository();
  final CategoriesRepository _categoriesRepo = CategoriesRepository();

  final List<StreamSubscription> _subs = [];
  List<ProductModel> products = [];
  List<CategoryModel> categories = [];
  /// Live totals from orders (productId → qty). Preferred over stale product.soldCount.
  Map<String, num> soldByProductId = {};
  String query = '';
  String? categoryFilter;
  bool isLoading = true;
  bool isSaving = false;
  bool isSyncingSold = false;
  String? error;

  List<ProductModel> get filtered {
    return products.where((p) {
      if (categoryFilter != null && p.cat != categoryFilter) return false;
      return p.matches(query);
    }).toList();
  }

  num soldCountOf(ProductModel product) =>
      soldByProductId[product.productId] ?? product.soldCount;

  @override
  void onInit() {
    super.onInit();
    _subs.add(_repo.watchProducts().listen(
      (items) {
        products = items;
        isLoading = false;
        error = null;
        update();
        update([listId]);
      },
      onError: (e) {
        error = '$e';
        isLoading = false;
        update();
      },
    ));
    _subs.add(_categoriesRepo.watchCategories().listen((items) {
      categories = items;
      update();
    }));
    // Load order counts immediately so the UI is not stuck on zeros.
    unawaited(syncSoldCounts(silent: true));
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  void setCategory(String? value) {
    categoryFilter = value;
    update();
    update([listId]);
  }

  Future<void> syncSoldCounts({bool silent = false}) async {
    if (isSyncingSold) return;
    isSyncingSold = true;
    update();
    try {
      soldByProductId = await _repo.loadSoldCountsFromOrders();
      final result = await _repo.recomputeSoldCountsFromOrders();
      update([listId]);
      if (!silent) {
        final sales = soldByProductId.length;
        AppSnackbar.show(
          sales == 0
              ? 'لا توجد طلبات لاحتسابها'
              : 'تم التحديث: $sales منتج له طلبات · كُتب ${result.updated} في قاعدة البيانات',
        );
      }
    } catch (e) {
      if (!silent) {
        AppSnackbar.show('تعذر مزامنة عدد الطلبات: $e', type: AppSnackbarType.error);
      }
    } finally {
      isSyncingSold = false;
      update();
      update([listId]);
    }
  }

  /// Sets an explicit display order number typed by the admin.
  Future<void> setTypedOrder(ProductModel product, String raw) async {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 1) {
      AppSnackbar.show('أدخل رقم ترتيب صحيح (١ فأكثر)', type: AppSnackbarType.error);
      update([listId]);
      return;
    }
    if (product.order == value) return;

    isSaving = true;
    update();
    try {
      await _repo.updateDisplayOrder(product.docId, value);
      AppSnackbar.show('تم حفظ الترتيب #$value');
    } catch (e) {
      AppSnackbar.show('تعذر حفظ الترتيب: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update();
      update([listId]);
    }
  }

  /// Reorders within the current filter while preserving global slots for other products.
  Future<void> onReorder(int oldIndex, int newIndex) async {
    final visible = filtered;
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= visible.length) return;

    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    final full = List<ProductModel>.from(products);
    final visibleIds = visible.map((p) => p.docId).toSet();
    final slots = <int>[];
    for (var i = 0; i < full.length; i++) {
      if (visibleIds.contains(full[i].docId)) slots.add(i);
    }
    for (var i = 0; i < slots.length && i < visible.length; i++) {
      full[slots[i]] = visible[i];
    }

    final orders = <String, int>{};
    for (var i = 0; i < full.length; i++) {
      orders[full[i].docId] = i + 1;
    }

    isSaving = true;
    update();
    try {
      await _repo.saveDisplayOrders(orders);
      products = [for (var i = 0; i < full.length; i++) full[i].copyWith(order: i + 1)];
      AppSnackbar.show('تم حفظ ترتيب العرض');
    } catch (e) {
      AppSnackbar.show('تعذر حفظ الترتيب: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update();
      update([listId]);
    }
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
