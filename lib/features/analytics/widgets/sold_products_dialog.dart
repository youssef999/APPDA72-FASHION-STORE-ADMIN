import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../models/analytics_report.dart';

class SoldProductsDialog extends StatelessWidget {
  final List<ProductSales> products;
  final num totalUnits;

  const SoldProductsDialog({
    super.key,
    required this.products,
    required this.totalUnits,
  });

  static Future<void> show({
    required List<ProductSales> products,
    required num totalUnits,
  }) {
    return Get.dialog(
      SoldProductsDialog(products: products, totalUnits: totalUnits),
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('القطع المباعة', style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          '${products.length} منتج · $totalUnits قطعة',
                          style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.divider),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text('لا توجد مبيعات في الفترة', style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => Divider(height: AppSpacing.lg, color: c.divider),
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${index + 1}',
                                style: AppTextStyles.h6.copyWith(color: index < 3 ? c.secondary : c.textDisabled),
                              ),
                            ),
                            AppNetworkImage(url: p.image, width: 48, height: 58, radius: AppRadius.sm),
                            const SizedBox(width: AppSpacing.sm + 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body1.copyWith(color: c.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.money(p.revenue),
                                    style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${p.units}',
                                    style: AppTextStyles.h5.copyWith(color: c.primary),
                                  ),
                                  Text('قطعة', style: AppTextStyles.caption.copyWith(color: c.textSecondary, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
