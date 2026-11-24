import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/coupons_controller.dart';
import '../models/coupon_model.dart';
import '../widgets/coupons_list.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.coupons,
      title: 'الكوبونات',
      body: GetBuilder<CouponsController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'كوبونات الخصم',
                subtitle: 'كوبون لكل المستخدمين أو لعميل واحد • مرة واحدة لكل عميل',
                actions: [
                  AppSearchField(hint: 'الكود أو العميل', onChanged: controller.search),
                  AppButton(label: 'كوبون جديد', icon: AppIcons.add, onPressed: controller.openForm),
                ],
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

  Widget _body(CouponsController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<CouponsController>(
      id: CouponsController.listId,
      builder: (controller) {
        final coupons = controller.filtered;
        if (coupons.isEmpty) {
          return const AppEmptyState(icon: AppIcons.coupon, title: 'لا توجد كوبونات', message: 'أنشئ كوبون جديد ليظهر للعملاء في التطبيق');
        }
        return CouponsList(coupons: coupons);
      },
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final CouponsController controller;

  const _StatusFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final statuses = <CouponStatus?>[null, ...CouponStatus.values];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: statuses.map((status) {
        final selected = controller.statusFilter == status;
        final label = status == null ? 'الكل' : CouponStatusChip.label(status);
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
