import 'package:get/get.dart';
import '../controllers/best_sellers_controller.dart';

class BestSellersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(BestSellersController.new);
  }
}
