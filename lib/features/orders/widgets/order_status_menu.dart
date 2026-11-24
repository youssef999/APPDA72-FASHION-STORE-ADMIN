import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/orders_controller.dart';
import '../models/order_model.dart';
import 'order_status_chip.dart';

/// Status chip that opens a menu to move the order to another status.
class OrderStatusMenu extends StatelessWidget {
  final OrderModel order;

  const OrderStatusMenu({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    if (controller.updating.contains(order.docId)) {
      return const SizedBox(width: AppIconSize.md, height: AppIconSize.md, child: CircularProgressIndicator(strokeWidth: 2));
    }
    final locked = order.status == OrderStatus.refused;
    return PopupMenuButton<String>(
      enabled: !locked,
      tooltip: locked ? 'الطلب مرفوض' : 'تغيير الحالة',
      color: context.colors.card,
      onSelected: (status) => controller.changeStatus(order, status),
      itemBuilder: (context) => OrderStatus.all
          .where((s) => s != order.status)
          .map((s) => PopupMenuItem<String>(
                value: s,
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: orderStatusColor(context, s)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(OrderStatus.label(s), style: AppTextStyles.body2),
                  ],
                ),
              ))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderStatusChip(status: order.status),
          if (!locked) Icon(Icons.expand_more_rounded, size: AppIconSize.sm, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
