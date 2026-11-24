import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../../../shared/widgets/layout/responsive_wrapper.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/breakdown_charts.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/product_insights.dart';
import '../widgets/range_selector.dart';
import '../widgets/revenue_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  static const List<String> _weekdays = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);
    return AdminScaffold(
      route: AppRoutes.analytics,
      title: 'التحليلات',
      body: GetBuilder<AnalyticsController>(
        builder: (controller) {
          final report = controller.report;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageToolbar(
                  title: 'تحليلات المتجر',
                  subtitle: 'الطلبات المرفوضة لا تُحسب في الإيرادات',
                  actions: [RangeSelector()],
                ),
                gap,
                if (controller.error != null)
                  AppErrorState(message: controller.error!)
                else if (report == null)
                  const AppLoader()
                else ...[
                  KpiGrid(report: report),
                  gap,
                  ResponsiveRow(flex: const [2, 1], children: [
                    RevenueChart(report: report, height: 300),
                    StatusDonut(counts: report.statusCounts),
                  ]),
                  gap,
                  ResponsiveRow(children: [
                    RankingBars(title: 'المبيعات حسب القسم', values: report.categoryRevenue, format: Formatters.money),
                    RankingBars(title: 'المقاسات الأكثر طلباً', subtitle: 'بعدد القطع', values: report.sizeUnits, format: (v) => '$v'),
                    RankingBars(title: 'الألوان الأكثر طلباً', subtitle: 'بعدد القطع', values: report.colorUnits, format: (v) => '$v'),
                  ]),
                  gap,
                  ResponsiveRow(children: [
                    DistributionBars(title: 'الطلبات حسب اليوم', values: report.weekdayOrders, labels: _weekdays),
                    DistributionBars(
                      title: 'الطلبات حسب الساعة',
                      values: report.hourOrders,
                      labels: List.generate(24, (h) => '$h'),
                      labelEvery: 3,
                    ),
                  ]),
                  gap,
                  ResponsiveRow(flex: const [3, 2, 2], breakpoint: 1100, children: [
                    TopProductsCard(products: report.topProducts),
                    StockAlertCard(title: 'مخزون منخفض', emptyText: 'لا توجد منتجات بمخزون منخفض', products: report.lowStock),
                    StockAlertCard(
                      title: 'بدون مبيعات في الفترة',
                      emptyText: 'كل المنتجات تم بيعها',
                      products: report.noSales,
                      showStock: false,
                    ),
                  ]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
