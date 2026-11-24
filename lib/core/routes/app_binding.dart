import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/branding/controllers/branding_controller.dart';
import '../../features/orders/controllers/orders_controller.dart';
import '../../features/shell/controllers/shell_controller.dart';

/// Controllers that live for the whole session.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController(), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    // BrandingController is session-scoped: sidebar + login + app title all read it.
    Get.lazyPut<BrandingController>(() => BrandingController(), fenix: true);
    // Shared by the dashboard, the orders page and the order dialog; a route-scoped instance
    // would be disposed by `offAllNamed` while another page still uses it.
    Get.lazyPut<OrdersController>(() => OrdersController(), fenix: true);
  }
}
