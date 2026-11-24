import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../../../shared/widgets/layout/responsive_wrapper.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../analytics/widgets/breakdown_charts.dart';
import '../../analytics/widgets/kpi_grid.dart';
import '../../analytics/widgets/revenue_chart.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../orders/widgets/orders_list.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/merchant_setup_checklist.dart';
import '../widgets/needs_attention_strip.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const int _recentCount = 6;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.dashboard,
      title: 'الرئيسية',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageToolbar(
              title: 'نظرة عامة على المتجر',
              subtitle: 'الطلبات تتحدّث مباشرة، والأعداد عند فتح الصفحة',
              actions: [
                AppButton(
                  label: 'تحديث',
                  icon: AppIcons.refresh,
                  variant: AppButtonVariant.outlined,
                  onPressed: Get.find<DashboardController>().loadCounts,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const MerchantSetupChecklist(),
            const NeedsAttentionStrip(),
            const DashboardStats(),
            const SizedBox(height: AppSpacing.lg),
            const _SalesSummary(),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              title: 'أحدث الطلبات',
              padding: const EdgeInsets.all(AppSpacing.md),
              trailing: AppButton(
                label: 'كل الطلبات',
                variant: AppButtonVariant.ghost,
                onPressed: () => Get.offAllNamed(AppRoutes.orders),
              ),
              child: GetBuilder<OrdersController>(
                builder: (controller) {
                  if (controller.isLoading) return const AppLoader();
                  if (controller.error != null) return AppErrorState(message: controller.error!);
                  if (controller.orders.isEmpty) {
                    return AppEmptyState(
                      icon: AppIcons.orders,
                      title: 'لا توجد طلبات بعد',
                      message: 'أضف منتجات وفعّل المتجر — الطلبات ستظهر هنا تلقائيًا',
                    );
                  }
                  return OrdersList(orders: controller.orders.take(_recentCount).toList(), shrinkWrap: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last 30 days from the shared analytics engine, with a link to the full analytics page.
class _SalesSummary extends StatelessWidget {
  const _SalesSummary();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AnalyticsController>(
      builder: (controller) {
        final report = controller.report;
        if (controller.error != null) return AppErrorState(message: controller.error!);
        if (report == null) return const AppLoader();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageToolbar(
              title: 'المبيعات آخر 30 يوماً',
              subtitle: 'مقارنة بالـ 30 يوماً السابقة',
              actions: [
                AppButton(
                  label: 'التحليلات الكاملة',
                  icon: AppIcons.analytics,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Get.offAllNamed(AppRoutes.analytics),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            KpiGrid(report: report, compact: true),
            const SizedBox(height: AppSpacing.lg),
            ResponsiveRow(flex: const [2, 1], children: [
              RevenueChart(report: report),
              StatusDonut(counts: report.statusCounts),
            ]),
          ],
        );
      },
    );
  }
}
