import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../products/models/product_model.dart';
import '../models/analytics_report.dart';

class TopProductsCard extends StatelessWidget {
  final List<ProductSales> products;

  const TopProductsCard({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      title: 'الأكثر مبيعاً',
      child: products.isEmpty
          ? Text('لا توجد مبيعات في الفترة', style: AppTextStyles.body2.copyWith(color: c.textSecondary))
          : Column(
              children: [
                for (var i = 0; i < products.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                    child: Row(children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}', style: AppTextStyles.h5.copyWith(color: i < 3 ? c.secondary : c.textDisabled)),
                      ),
                      AppNetworkImage(url: products[i].image, width: 44, height: 54, radius: AppRadius.sm),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(products[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                          Text('${products[i].units} قطعة', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                        ]),
                      ),
                      Text(Formatters.money(products[i].revenue), style: AppTextStyles.h6.copyWith(color: c.secondary)),
                    ]),
                  ),
              ],
            ),
    );
  }
}

/// Low-stock or unsold products; [limit] keeps the card short.
class StockAlertCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<ProductModel> products;
  final bool showStock;
  final int limit;

  const StockAlertCard({
    super.key,
    required this.title,
    required this.emptyText,
    required this.products,
    this.showStock = true,
    this.limit = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      title: title,
      trailing: Text('${products.length}', style: AppTextStyles.h6.copyWith(color: c.textSecondary)),
      child: products.isEmpty
          ? Text(emptyText, style: AppTextStyles.body2.copyWith(color: c.textSecondary))
          : Column(
              children: products.take(limit).map((p) {
                final Color color = p.quant <= 0 ? c.error : c.warning;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(children: [
                    AppNetworkImage(url: p.image, width: 36, height: 44, radius: AppRadius.sm),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Text(p.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
                    ),
                    if (showStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(AppIcons.stock, size: AppIconSize.sm - 4, color: color),
                          const SizedBox(width: AppSpacing.xs),
                          Text(p.quant <= 0 ? 'نفد' : '${p.quant}', style: AppTextStyles.caption.copyWith(color: color)),
                        ]),
                      )
                    else
                      Text(Formatters.money(p.price), style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  ]),
                );
              }).toList(),
            ),
    );
  }
}
