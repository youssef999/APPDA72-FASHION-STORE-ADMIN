import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/web_link_actions.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../controllers/orders_controller.dart';
import '../models/order_model.dart';
import 'order_status_menu.dart';

/// Reads the order from the controller so status changes show immediately.
class OrderDetailsDialog extends StatelessWidget {
  final String docId;

  const OrderDetailsDialog({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: GetBuilder<OrdersController>(
          builder: (controller) {
            final order = controller.byDocId(docId);
            if (order == null) return const SizedBox(height: 120);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('طلب #${order.orderId}', style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
                            Text(Formatters.dateTime(order.createdAt), style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                      OrderStatusMenu(order: order),
                      const SizedBox(width: AppSpacing.sm),
                      AppIconButton(icon: AppIcons.close, onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.divider),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _Section(title: 'العميل', children: [
                        _InfoLine(icon: AppIcons.users, text: order.customerName),
                        _InfoLine(icon: AppIcons.phone, text: order.phone),
                        if (order.userEmail.isNotEmpty) _InfoLine(icon: AppIcons.email, text: order.userEmail),
                        _InfoLine(
                          icon: AppIcons.location,
                          text: [order.address, order.area, if (order.building.isNotEmpty) 'مبنى ${order.building}', if (order.floor.isNotEmpty) 'دور ${order.floor}', if (order.home.isNotEmpty) 'شقة ${order.home}']
                              .where((e) => e.isNotEmpty)
                              .join(' • '),
                        ),
                        if (order.hasCoordinates) _LocationActions(order: order),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      _Section(title: 'الدفع', children: [
                        _InfoLine(icon: AppIcons.revenue, text: order.paymentMethodLabel),
                        _InfoLine(icon: AppIcons.pending, text: order.paymentStatusLabel),
                        if (order.paymentGateway.isNotEmpty &&
                            order.paymentGateway != order.paymentMethod)
                          _InfoLine(
                            icon: AppIcons.link,
                            text: 'البوابة: ${order.paymentGateway}',
                          ),
                      ]),
                      if (order.orderNote.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _Section(title: 'ملاحظات الطلب', children: [
                          _InfoLine(icon: AppIcons.edit, text: order.orderNote),
                        ]),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _Section(
                        title: 'المنتجات (${order.itemCount})',
                        children: order.items.map((item) => _ItemTile(item: item)).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Section(title: 'الحساب', children: [
                        _TotalLine(label: 'المجموع', value: Formatters.money(order.subtotal)),
                        if (order.discount > 0)
                          _TotalLine(label: 'خصم الكوبون ${order.couponCode}', value: '- ${Formatters.money(order.discount)}'),
                        _TotalLine(label: 'التوصيل', value: Formatters.money(order.deliveryFee)),
                        _TotalLine(label: 'الإجمالي', value: Formatters.money(order.finalTotal), strong: true),
                      ]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.overline.copyWith(color: context.colors.secondary)),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      );
}

class _LocationActions extends StatelessWidget {
  final OrderModel order;

  const _LocationActions({required this.order});

  Future<void> _shareLink() async {
    await WebLinkActions.copyText(order.mapsShareLink);
    AppSnackbar.show('تم نسخ رابط الموقع', type: AppSnackbarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.pin, size: AppIconSize.sm, color: c.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SelectableText(
                    order.coordinatesLabel,
                    style: AppTextStyles.body2.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'فتح في خرائط جوجل',
                  icon: AppIcons.location,
                  onPressed: () => WebLinkActions.openExternal(order.googleMapsUrl),
                ),
                AppButton(
                  label: 'نسخ رابط الموقع',
                  icon: AppIcons.link,
                  variant: AppButtonVariant.outlined,
                  onPressed: _shareLink,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.sm, color: c.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: SelectableText(text.isEmpty ? '—' : text, style: AppTextStyles.body2.copyWith(color: c.textPrimary))),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OrderItemModel item;

  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final options = [
      if (item.colorAr.isNotEmpty || item.color.isNotEmpty) item.colorAr.isNotEmpty ? item.colorAr : item.color,
      if (item.size.isNotEmpty) 'مقاس ${item.size}',
      'الكمية ${item.quantity}',
    ].join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Row(
        children: [
          AppNetworkImage(url: item.image, width: 52, height: 64),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                Text(options, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Text(Formatters.money(item.lineTotal), style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _TotalLine({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = strong ? AppTextStyles.h5.copyWith(color: c.secondary) : AppTextStyles.body2.copyWith(color: c.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}
