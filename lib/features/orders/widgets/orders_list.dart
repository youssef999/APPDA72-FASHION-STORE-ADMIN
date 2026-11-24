import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../models/order_model.dart';
import 'order_details_dialog.dart';
import 'order_status_menu.dart';

/// Table rows on tablet/desktop, stacked cards on mobile.
class OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool shrinkWrap;

  const OrdersList({super.key, required this.orders, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: orders.length + (isMobile ? 0 : 1),
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? AppSpacing.sm + 4 : 0),
      itemBuilder: (context, index) {
        if (!isMobile && index == 0) return const _HeaderRow();
        final order = orders[isMobile ? index : index - 1];
        return isMobile ? _OrderCard(order: order) : _OrderRow(order: order);
      },
    );
  }
}

void _openDetails(OrderModel order) => Get.dialog(OrderDetailsDialog(docId: order.docId));

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: context.colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('رقم الطلب', style: style)),
          Expanded(flex: 3, child: Text('العميل', style: style)),
          Expanded(flex: 2, child: Text('الدفع', style: style)),
          Expanded(flex: 3, child: Text('التاريخ', style: style)),
          Expanded(flex: 1, child: Text('القطع', style: style)),
          Expanded(flex: 2, child: Text('الإجمالي', style: style)),
          Expanded(flex: 3, child: Text('الحالة', style: style)),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => _openDetails(order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text('#${order.orderId}', style: AppTextStyles.h6.copyWith(color: c.textPrimary))),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
                  Text(order.phone, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.paymentMethodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(color: c.textPrimary),
              ),
            ),
            Expanded(flex: 3, child: Text(Formatters.dateTime(order.createdAt), style: AppTextStyles.body2.copyWith(color: c.textSecondary))),
            Expanded(flex: 1, child: Text('${order.itemCount}', style: AppTextStyles.body2.copyWith(color: c.textPrimary))),
            Expanded(flex: 2, child: Text(Formatters.money(order.finalTotal), style: AppTextStyles.h6.copyWith(color: c.secondary))),
            Expanded(flex: 3, child: Align(alignment: AlignmentDirectional.centerStart, child: OrderStatusMenu(order: order))),
            AppIconButton(icon: Icons.visibility_outlined, tooltip: 'التفاصيل', onPressed: () => _openDetails(order)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => _openDetails(order),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('#${order.orderId}', style: AppTextStyles.h6.copyWith(color: c.textPrimary))),
                OrderStatusMenu(order: order),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(order.customerName, style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${order.paymentMethodLabel} · ${order.paymentStatusLabel}',
              style: AppTextStyles.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(AppIcons.pending, size: AppIconSize.sm, color: c.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(Formatters.dateTime(order.createdAt), style: AppTextStyles.caption.copyWith(color: c.textSecondary))),
                Text(Formatters.money(order.finalTotal), style: AppTextStyles.h6.copyWith(color: c.secondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
