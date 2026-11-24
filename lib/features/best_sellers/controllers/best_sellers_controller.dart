import 'dart:async';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../products/models/product_model.dart';
import '../../products/repositories/products_repository.dart';

class BestSellersController extends GetxController {
  static const String listId = 'best_sellers_list';

  final ProductsRepository _repo = ProductsRepository();

  StreamSubscription? _sub;
  List<ProductModel> products = [];
  String query = '';
  bool pinnedOnly = false;
  bool isLoading = true;
  bool isSyncingSold = false;
  String? error;
  Map<String, num> soldByProductId = {};

  num soldCountOf(ProductModel product) => soldByProductId[product.productId] ?? product.soldCount;

  List<ProductModel> get filtered {
    var list = products.where((p) {
      if (pinnedOnly && !p.isBestSeller) return false;
      if (query.isEmpty) return true;
      return p.matches(query);
    }).toList();
    list.sort((a, b) {
      if (a.isBestSeller != b.isBestSeller) return a.isBestSeller ? -1 : 1;
      final sold = soldCountOf(b).compareTo(soldCountOf(a));
      if (sold != 0) return sold;
      return a.displayName.compareTo(b.displayName);
    });
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchProducts().listen(
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
    );
    unawaited(syncSoldCounts(silent: true));
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  void setPinnedOnly(bool value) {
    pinnedOnly = value;
    update();
    update([listId]);
  }

  Future<void> togglePin(ProductModel product) async {
    try {
      await _repo.setBestSeller(product.docId, !product.isBestSeller);
      AppSnackbar.show(product.isBestSeller ? 'أُزيل التثبيت' : 'تم التثبيت في الأفضل مبيعاً');
    } catch (e) {
      AppSnackbar.show('تعذر تحديث المنتج: $e', type: AppSnackbarType.error);
    }
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
        AppSnackbar.show(
          soldByProductId.isEmpty
              ? 'لا توجد طلبات لاحتسابها'
              : 'تم التحديث: ${soldByProductId.length} منتج له طلبات · كُتب ${result.updated} في قاعدة البيانات',
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

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
