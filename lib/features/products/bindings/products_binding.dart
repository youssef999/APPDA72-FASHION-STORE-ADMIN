import 'package:get/get.dart';
import '../controllers/product_form_controller.dart';
import '../controllers/products_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductsController>(() => ProductsController());
  }
}

class ProductFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductFormController>(() => ProductFormController());
  }
}
