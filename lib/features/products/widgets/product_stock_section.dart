import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/product_form_controller.dart';
import 'product_info_section.dart';

/// Price, discount and per-size stock; the total stock is recalculated as rows change.
class ProductStockSection extends StatelessWidget {
  const ProductStockSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ProductFormController>(
      id: ProductFormController.stockId,
      builder: (controller) {
        final price = Formatters.toNum(controller.price.text);
        final old = Formatters.toNum(controller.oldPrice.text);
        final discount = old > price && price > 0 ? ((old - price) / old * 100).floor() : 0;
        return AppCard(
          title: 'السعر والمخزون',
          trailing: Text('الإجمالي: ${controller.totalStock}', style: AppTextStyles.h6.copyWith(color: c.secondary)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldPair(
                first: AppTextField(
                  label: 'السعر الحالي',
                  controller: controller.price,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.refreshStock(),
                ),
                second: AppTextField(
                  label: 'السعر قبل الخصم (0 = بدون خصم)',
                  controller: controller.oldPrice,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.refreshStock(),
                ),
              ),
              if (discount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('سيظهر في التطبيق بخصم $discount%', style: AppTextStyles.caption.copyWith(color: c.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('المقاسات والكمية لكل مقاس', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              if (controller.stock.isEmpty)
                AppTextField(
                  label: 'الكمية (منتج بدون مقاسات)',
                  controller: controller.quant,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.refreshStock(),
                ),
              ...List.generate(controller.stock.length, (index) {
                final row = controller.stock[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: AppTextField(label: 'المقاس', controller: row.size, textDirection: TextDirection.ltr)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          label: 'الكمية',
                          controller: row.quantity,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => controller.refreshStock(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: AppIconButton(icon: AppIcons.delete, color: c.error, onPressed: () => controller.removeSize(index)),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(label: 'إضافة مقاس', icon: AppIcons.add, variant: AppButtonVariant.ghost, onPressed: controller.addSize),
              ),
            ],
          ),
        );
      },
    );
  }
}
