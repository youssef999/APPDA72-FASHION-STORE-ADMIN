import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/cards/chart_card.dart';
import '../../orders/models/order_model.dart';
import '../../orders/widgets/order_status_chip.dart';

class StatusDonut extends StatelessWidget {
  final Map<String, int> counts;

  const StatusDonut({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = counts.values.fold<int>(0, (s, v) => s + v);
    final entries = counts.entries.where((e) => e.value > 0).toList();
    return ChartCard(
      title: 'حالات الطلبات',
      subtitle: '$total طلب في الفترة',
      isEmpty: total == 0,
      chart: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 56,
                  sections: entries
                      .map((e) => PieChartSectionData(
                            value: e.value.toDouble(),
                            color: orderStatusColor(context, e.key),
                            radius: 26,
                            showTitle: false,
                          ))
                      .toList(),
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
                  Text('طلب', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: OrderStatus.all.map((s) {
              final value = counts[s] ?? 0;
              final pct = total == 0 ? 0 : (value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: orderStatusColor(context, s), shape: BoxShape.circle)),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${OrderStatus.label(s)}  $value ($pct%)', style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Ranked horizontal bars; reads well in RTL and with long Arabic labels.
class RankingBars extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, num> values;
  final String Function(num value) format;
  final int limit;

  const RankingBars({
    super.key,
    required this.title,
    required this.values,
    required this.format,
    this.subtitle,
    this.limit = 6,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = values.entries.take(limit).toList();
    final max = entries.isEmpty ? 0 : entries.first.value;
    return ChartCard(
      title: title,
      subtitle: subtitle,
      isEmpty: entries.isEmpty,
      chart: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 4),
        itemBuilder: (context, index) {
          final e = entries[index];
          final color = AppChartColors.at(context, index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body2.copyWith(color: c.textPrimary))),
                Text(format(e.value), style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
              ]),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : (e.value / max).toDouble(),
                  minHeight: 8,
                  color: color,
                  backgroundColor: c.divider,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Orders per weekday or per hour.
class DistributionBars extends StatelessWidget {
  final String title;
  final List<int> values;
  final List<String> labels;
  final int labelEvery;

  const DistributionBars({super.key, required this.title, required this.values, required this.labels, this.labelEvery = 1});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    return ChartCard(
      title: title,
      isEmpty: max == 0,
      height: 220,
      chart: Directionality(
        textDirection: TextDirection.ltr,
        child: BarChart(BarChartData(
          maxY: max * 1.25,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i % labelEvery != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(labels[i], style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.light.primary,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${labels[group.x]}: ${rod.toY.toInt()} طلب',
                AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: values.length > 12 ? 8 : 18,
                  color: values[i] == max ? c.secondary : c.secondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                ),
              ]),
          ],
        )),
      ),
    );
  }
}
