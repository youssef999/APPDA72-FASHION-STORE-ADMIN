import 'package:get/get.dart';
import '../controllers/product_import_controller.dart';

class ProductImportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductImportController>(() => ProductImportController());
  }
}
