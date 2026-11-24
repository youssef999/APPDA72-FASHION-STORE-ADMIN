import 'package:get/get.dart';
import '../../features/analytics/bindings/analytics_binding.dart';
import '../../features/analytics/pages/analytics_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/categories/bindings/categories_binding.dart';
import '../../features/categories/pages/categories_page.dart';
import '../../features/coupons/bindings/coupons_binding.dart';
import '../../features/coupons/pages/coupons_page.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/drops/bindings/drops_binding.dart';
import '../../features/drops/pages/drops_page.dart';
import '../../features/best_sellers/bindings/best_sellers_binding.dart';
import '../../features/best_sellers/pages/best_sellers_page.dart';
import '../../features/branding/bindings/branding_binding.dart';
import '../../features/branding/pages/branding_page.dart';
import '../../features/seasonal/bindings/seasonal_binding.dart';
import '../../features/seasonal/pages/seasonal_page.dart';
import '../../features/payments/bindings/payments_binding.dart';
import '../../features/payments/pages/payments_page.dart';
import '../../features/feedback/bindings/feedback_binding.dart';
import '../../features/feedback/pages/feedback_page.dart';
import '../../features/product_order/bindings/product_order_binding.dart';
import '../../features/product_order/pages/product_order_page.dart';
import '../../features/notifications/bindings/notifications_binding.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/orders/pages/orders_page.dart';
import '../../features/product_import/bindings/product_import_binding.dart';
import '../../features/product_import/pages/product_import_page.dart';
import '../../features/products/bindings/products_binding.dart';
import '../../features/products/pages/product_form_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/store_settings/bindings/store_settings_binding.dart';
import '../../features/store_settings/pages/store_settings_page.dart';
import '../../features/users/bindings/users_binding.dart';
import '../../features/users/pages/users_page.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

/// `OrdersController` is registered app-wide in `AppBinding`, so the orders page needs no binding.
class AppPages {
  AppPages._();

  static final List<GetMiddleware> _admin = [AuthMiddleware()];

  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.login, page: () => const LoginPage(), middlewares: [GuestMiddleware()]),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.analytics,
      page: () => const AnalyticsPage(),
      binding: AnalyticsBinding(),
      middlewares: _admin,
    ),
    GetPage(name: AppRoutes.orders, page: () => const OrdersPage(), middlewares: _admin),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsPage(),
      binding: ProductsBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.productForm,
      page: () => const ProductFormPage(),
      binding: ProductFormBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.productImport,
      page: () => const ProductImportPage(),
      binding: ProductImportBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesPage(),
      binding: CategoriesBinding(),
      middlewares: _admin,
    ),
    GetPage(name: AppRoutes.coupons, page: () => const CouponsPage(), binding: CouponsBinding(), middlewares: _admin),
    GetPage(
      name: AppRoutes.drops,
      page: () => const DropsPage(),
      binding: DropsBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.bestSellers,
      page: () => const BestSellersPage(),
      binding: BestSellersBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.productOrder,
      page: () => const ProductOrderPage(),
      binding: ProductOrderBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackPage(),
      binding: FeedbackBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.branding,
      page: () => const BrandingPage(),
      binding: BrandingBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.storeSettings,
      page: () => const StoreSettingsPage(),
      binding: StoreSettingsBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.seasonal,
      page: () => const SeasonalPage(),
      binding: SeasonalBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const PaymentsPage(),
      binding: PaymentsBinding(),
      middlewares: _admin,
    ),
    GetPage(name: AppRoutes.users, page: () => const UsersPage(), binding: UsersBinding(), middlewares: _admin),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
      middlewares: _admin,
    ),
  ];
}
