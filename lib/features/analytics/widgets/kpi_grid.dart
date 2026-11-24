import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../models/analytics_report.dart';
import 'sold_products_dialog.dart';

class KpiGrid extends StatelessWidget {
  final AnalyticsReport report;
  final bool compact;

  const KpiGrid({super.key, required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = report.current;
    final before = report.previous;
    final items = [
      _Kpi('الإيرادات', Formatters.money(now.revenue), AppIcons.revenue, c.secondary, AnalyticsReport.change(now.revenue, before.revenue)),
      _Kpi('الطلبات', '${now.orders}', AppIcons.orders, c.info, AnalyticsReport.change(now.orders, before.orders)),
      _Kpi('متوسط الطلب', Formatters.money(now.averageOrder), Icons.shopping_bag_outlined, c.success,
          AnalyticsReport.change(now.averageOrder, before.averageOrder)),
      _Kpi(
        'القطع المباعة',
        '${now.units}',
        AppIcons.products,
        c.primary,
        AnalyticsReport.change(now.units, before.units),
        actionLabel: 'عرض القطع',
        onAction: () => SoldProductsDialog.show(
          products: report.soldProducts,
          totalUnits: now.units,
        ),
      ),
      if (!compact) ...[
        _Kpi('نسبة الرفض', '${(now.refusalRate * 100).toStringAsFixed(1)}%', Icons.block_rounded, c.error,
            AnalyticsReport.change(now.refusalRate, before.refusalRate),
            lowerIsBetter: true),
        _Kpi('مستخدمون جدد', '${now.newUsers}', AppIcons.users, c.warning, AnalyticsReport.change(now.newUsers, before.newUsers)),
      ],
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 128,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _KpiCard(kpi: items[index]),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final double? change;
  final bool lowerIsBetter;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Kpi(
    this.label,
    this.value,
    this.icon,
    this.tint,
    this.change, {
    this.lowerIsBetter = false,
    this.actionLabel,
    this.onAction,
  });
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;

  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final change = kpi.change;
    final positive = change != null && (kpi.lowerIsBetter ? change <= 0 : change >= 0);
    final Color changeColor = change == null ? c.textSecondary : (positive ? c.success : c.error);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: kpi.tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(kpi.icon, color: kpi.tint, size: AppIconSize.lg),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kpi.label, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(kpi.value, style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
                ),
                if (kpi.onAction != null && kpi.actionLabel != null)
                  TextButton(
                    onPressed: kpi.onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: kpi.tint,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      kpi.actionLabel!,
                      style: AppTextStyles.caption.copyWith(color: kpi.tint, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        change == null
                            ? Icons.remove_rounded
                            : (change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
                        size: AppIconSize.sm,
                        color: changeColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          change == null ? 'جديد' : '${change.abs().toStringAsFixed(1)}% عن الفترة السابقة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: changeColor),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
