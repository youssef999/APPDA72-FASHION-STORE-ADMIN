import 'package:get/get.dart';
import '../controllers/store_settings_controller.dart';

class StoreSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(StoreSettingsController.new);
  }
}
