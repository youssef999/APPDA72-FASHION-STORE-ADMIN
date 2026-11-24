import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isAdmin = Get.find<AuthController>().isAdmin;
    return isAdmin ? null : const RouteSettings(name: AppRoutes.login);
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isAdmin = Get.find<AuthController>().isAdmin;
    return isAdmin ? const RouteSettings(name: AppRoutes.dashboard) : null;
  }
}
