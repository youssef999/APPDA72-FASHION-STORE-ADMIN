import 'package:get/get.dart';
import '../controllers/seasonal_controller.dart';

class SeasonalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(SeasonalAdminController.new);
  }
}
