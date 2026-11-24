import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/chart_card.dart';
import '../models/analytics_report.dart';

/// Revenue area line with the order count in the tooltip.
class RevenueChart extends StatelessWidget {
  final AnalyticsReport report;
  final double height;

  const RevenueChart({super.key, required this.report, this.height = 260});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final series = report.series;
    final maxY = series.fold<num>(0, (m, p) => math.max(m, p.revenue)).toDouble();
    final labelEvery = math.max(1, (series.length / 7).ceil());
    final bucketLabel = switch (report.bucket) {
      AnalyticsBucket.day => 'يومي',
      AnalyticsBucket.week => 'أسبوعي',
      AnalyticsBucket.month => 'شهري',
    };
    String label(DateTime d) => switch (report.bucket) {
          AnalyticsBucket.month => DateFormat('MMM', 'en').format(d),
          _ => DateFormat('d/M', 'en').format(d),
        };

    return ChartCard(
      title: 'حركة المبيعات',
      subtitle: 'الإيرادات ($bucketLabel)',
      height: height,
      isEmpty: maxY == 0,
      chart: Directionality(
        textDirection: TextDirection.ltr,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY == 0 ? 1 : maxY * 1.2,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: c.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(NumberFormat.compact(locale: 'en').format(value),
                        style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= series.length || i % labelEvery != 0) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(label(series[i].start), style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.light.primary,
                tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
                getTooltipItems: (spots) => spots.map((s) {
                  final point = series[s.x.toInt()];
                  return LineTooltipItem(
                    '${label(point.start)}\n${Formatters.money(point.revenue)} • ${point.orders} طلب',
                    AppTextStyles.caption.copyWith(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].revenue.toDouble())],
                isCurved: true,
                preventCurveOverShooting: true,
                color: c.secondary,
                barWidth: 3,
                dotData: FlDotData(show: series.length <= 14),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.secondary.withValues(alpha: 0.28), c.secondary.withValues(alpha: 0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
