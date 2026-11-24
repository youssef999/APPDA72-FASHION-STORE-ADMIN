import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/analytics_controller.dart';

class RangeSelector extends StatelessWidget {
  const RangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<AnalyticsController>();
    final format = DateFormat('d/M/yyyy', 'en');
    final custom = controller.customRange;
    final options = {
      AnalyticsRange.week: '7 أيام',
      AnalyticsRange.month: '30 يوماً',
      AnalyticsRange.quarter: '90 يوماً',
      AnalyticsRange.year: 'سنة',
      AnalyticsRange.custom: controller.range == AnalyticsRange.custom
          ? '${format.format(custom.start)} - ${format.format(custom.end)}'
          : 'فترة مخصصة',
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.entries.map((e) {
        final selected = controller.range == e.key;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          selectedColor: c.primary,
          label: Text(e.value, style: AppTextStyles.caption.copyWith(color: selected ? c.onPrimary : c.textPrimary)),
          onSelected: (_) async {
            if (e.key != AnalyticsRange.custom) return controller.setRange(e.key);
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
              initialDateRange: custom,
            );
            if (picked != null) controller.setCustomRange(picked);
          },
        );
      }).toList(),
    );
  }
}
