import 'dart:async';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/categories_repository.dart';
import '../models/product_model.dart';
import '../repositories/products_repository.dart';

enum StockFilter { all, low, out }

class ProductsController extends GetxController {
  static const String gridId = 'products_grid';
  static const int lowStockLimit = 3;

  final ProductsRepository _repository = ProductsRepository();
  final CategoriesRepository _categoriesRepository = CategoriesRepository();
  final List<StreamSubscription> _subscriptions = [];

  List<ProductModel> products = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? error;
  String query = '';
  String? categoryFilter;
  StockFilter stockFilter = StockFilter.all;

  List<ProductModel> get filtered => products.where((p) {
        if (categoryFilter != null && p.cat != categoryFilter) return false;
        if (stockFilter == StockFilter.low && (p.quant <= 0 || p.quant > lowStockLimit)) return false;
        if (stockFilter == StockFilter.out && p.quant > 0) return false;
        return p.matches(query);
      }).toList();

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(_repository.watchProducts().listen(
      (data) {
        products = data;
        isLoading = false;
        error = null;
        update();
      },
      onError: (Object e) {
        isLoading = false;
        error = '$e';
        update();
      },
    ));
    _subscriptions.add(_categoriesRepository.watchCategories().listen((data) {
      categories = data;
      update();
    }));
  }

  void search(String value) {
    query = value.trim();
    update([gridId]);
  }

  void setCategory(String? value) {
    categoryFilter = value;
    update();
  }

  void setStockFilter(StockFilter value) {
    stockFilter = value;
    update();
  }

  void openForm([ProductModel? product]) => Get.toNamed(
        AppRoutes.productForm,
        parameters: product == null ? null : {'id': product.docId},
      );

  Future<void> delete(ProductModel product) async {
    final confirmed = await AppConfirmDialog.show(
      title: 'حذف المنتج',
      message: 'سيتم حذف "${product.displayName}" نهائياً من المتجر.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await _repository.delete(product.docId);
      AppSnackbar.show('تم حذف المنتج');
    } catch (e) {
      AppSnackbar.show('تعذر حذف المنتج: $e', type: AppSnackbarType.error);
    }
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.onClose();
  }
}
