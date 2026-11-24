import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/stat_card.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../orders/models/order_model.dart';
import '../controllers/dashboard_controller.dart';
import '../repositories/dashboard_repository.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<OrdersController>(
      builder: (orders) => GetBuilder<DashboardController>(
        builder: (dashboard) {
          final counts = dashboard.counts;
          String count(int? value) => dashboard.isLoading ? '…' : '${value ?? '—'}';
          String live(String value) => orders.isLoading ? '…' : value;
          final cards = [
            StatCard(
              label: 'كل الطلبات',
              value: live('${orders.countFor(null)}'),
              icon: AppIcons.orders,
              onTap: () => Get.offAllNamed(AppRoutes.orders),
            ),
            StatCard(
              label: 'طلبات بانتظار المراجعة',
              value: live('${orders.countFor(OrderStatus.waiting)}'),
              icon: AppIcons.pending,
              tint: c.warning,
              onTap: () => Get.offAllNamed(AppRoutes.orders),
            ),
            StatCard(
              label: 'إيرادات الطلبات المُسلّمة',
              value: live(Formatters.money(orders.deliveredRevenue)),
              icon: AppIcons.revenue,
              tint: c.success,
            ),
            StatCard(
              label: 'المنتجات',
              value: count(counts?.products),
              icon: AppIcons.products,
              onTap: () => Get.offAllNamed(AppRoutes.products),
            ),
            StatCard(
              label: 'مخزون منخفض (${DashboardRepository.lowStockLimit} أو أقل)',
              value: count(counts?.lowStock),
              icon: AppIcons.stock,
              tint: c.error,
              onTap: () => Get.offAllNamed(AppRoutes.products),
            ),
            StatCard(
              label: 'المستخدمون',
              value: count(counts?.users),
              icon: AppIcons.users,
              tint: c.info,
              onTap: () => Get.offAllNamed(AppRoutes.users),
            ),
          ];
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 96,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: cards.length,
            itemBuilder: (_, index) => cards[index],
          );
        },
      ),
    );
  }
}
