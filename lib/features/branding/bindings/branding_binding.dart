import 'package:get/get.dart';
import '../controllers/branding_controller.dart';

class BrandingBinding extends Bindings {
  @override
  void dependencies() {
    // Controller is session-scoped via AppBinding (fenix: true); skip re-registration
    // to prevent disposal when this route is popped.
    if (!Get.isRegistered<BrandingController>()) {
      Get.lazyPut(BrandingController.new, fenix: true);
    }
  }
}
