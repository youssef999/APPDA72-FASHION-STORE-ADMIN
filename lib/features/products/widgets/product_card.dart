import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/color_parser.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../controllers/products_controller.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<ProductsController>();
    final Color stockColor = product.quant <= 0
        ? c.error
        : product.quant <= ProductsController.lowStockLimit
            ? c.warning
            : c.success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, box) => AppNetworkImage(
                      url: product.thumbnail.isNotEmpty ? product.thumbnail : product.image,
                      width: box.maxWidth,
                      height: box.maxHeight,
                    ),
                  ),
                ),
                if (product.onSale)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: _Badge(text: '-${product.discountPercent}%', color: c.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            product.brand.isNotEmpty ? product.brand.toUpperCase() : (product.catAr.isNotEmpty ? product.catAr : product.cat),
            maxLines: 1,
            style: AppTextStyles.overline.copyWith(color: c.secondary),
          ),
          Text(product.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(Formatters.money(product.price), style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
              if (product.onSale) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  Formatters.money(product.oldPrice),
                  style: AppTextStyles.caption.copyWith(color: c.textDisabled, decoration: TextDecoration.lineThrough),
                ),
              ],
              const Spacer(),
              ...product.colors.take(3).map((color) => Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsetsDirectional.only(start: 2),
                    decoration: BoxDecoration(
                      color: parseHexColor(color.hex) ?? c.border,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(AppIcons.stock, size: AppIconSize.sm, color: stockColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  product.quant <= 0 ? 'نفد المخزون' : 'المخزون ${product.quant} • ${product.sizes.join(' ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: stockColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'تعديل',
                  icon: AppIcons.edit,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.openForm(product),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(icon: AppIcons.delete, color: c.error, tooltip: 'حذف', onPressed: () => controller.delete(product)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Text(text, style: AppTextStyles.caption.copyWith(color: Colors.white)),
      );
}
