import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'app_card.dart';

/// Card with a fixed chart height so grids of charts line up.
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final Widget chart;
  final bool isEmpty;
  final Widget? trailing;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.height = 260,
    this.isEmpty = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
                    if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: height,
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_outlined, size: AppIconSize.xl, color: c.textDisabled),
                        const SizedBox(height: AppSpacing.sm),
                        Text('لا توجد بيانات في هذه الفترة', style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  )
                : chart,
          ),
        ],
      ),
    );
  }
}
