import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/orders_controller.dart';
import '../models/order_model.dart';
import '../widgets/orders_list.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.orders,
      title: 'الطلبات',
      body: GetBuilder<OrdersController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'إدارة الطلبات',
                subtitle: 'غيّر حالة الطلب وسيصل إشعار للعميل في التطبيق',
                actions: [AppSearchField(hint: 'رقم الطلب، الاسم أو الهاتف', onChanged: controller.search)],
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusFilters(controller: controller),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppCard(
                  expand: true,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _body(controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(OrdersController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<OrdersController>(
      id: OrdersController.listId,
      builder: (controller) {
        final orders = controller.filtered;
        if (orders.isEmpty) {
          return const AppEmptyState(icon: AppIcons.orders, title: 'لا توجد طلبات', message: 'لا توجد طلبات مطابقة للفلتر الحالي');
        }
        return OrdersList(orders: orders);
      },
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final OrdersController controller;

  const _StatusFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final statuses = <String?>[null, ...OrderStatus.all];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: statuses.map((status) {
        final selected = controller.statusFilter == status;
        final label = status == null ? 'الكل' : OrderStatus.label(status);
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          selectedColor: c.primary,
          label: Text(
            '$label (${controller.countFor(status)})',
            style: AppTextStyles.caption.copyWith(color: selected ? c.onPrimary : c.textPrimary),
          ),
          onSelected: (_) => controller.setStatusFilter(status),
        );
      }).toList(),
    );
  }
}
