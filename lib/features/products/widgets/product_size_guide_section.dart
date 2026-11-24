import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/product_form_controller.dart';
import '../models/product_model.dart';

class ProductSizeGuideSection extends StatelessWidget {
  const ProductSizeGuideSection({super.key});

  static const _templates = <String, String>{
    'assets/images/size_guide_dresses.jpg': 'فساتين / عبايات',
    'assets/images/size_guide_tops.jpg': 'بلوزات / توبات',
    'assets/images/size_guide_bottoms.jpg': 'بناطيل / تنانير',
    'assets/images/size_guide_shoes.jpg': 'أحذية',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ProductFormController>(
      id: ProductFormController.sizeGuideId,
      builder: (controller) {
        return AppCard(
          title: 'دليل المقاسات والترشيح الذكي',
          trailing: AppButton(
            label: controller.sizeGuideEnabled ? 'تعطيل' : 'تفعيل',
            variant: AppButtonVariant.ghost,
            icon: AppIcons.straighten,
            onPressed: controller.toggleSizeGuide,
          ),
          child: !controller.sizeGuideEnabled
              ? Text(
                  'فعّل الدليل لإدخال قياسات العرض/الطول ونطاقات الطول والوزن لترشيح المقاس في التطبيق.',
                  style: AppTextStyles.body2.copyWith(color: c.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDropdown<String>(
                      label: 'نوع القصة (fitType)',
                      value: controller.fitType,
                      items: const [
                        AppDropdownItem(ProductModel.fitRegular, 'عادية (regular)'),
                        AppDropdownItem(ProductModel.fitSlim, 'ضيقة (slim)'),
                        AppDropdownItem(ProductModel.fitOversized, 'واسعة (oversized)'),
                      ],
                      onChanged: controller.setFitType,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdown<String>(
                      label: 'قالب الرسم التوضيحي',
                      value: controller.sizeGuideImage,
                      items: _templates.entries.map((e) => AppDropdownItem(e.key, e.value)).toList(),
                      onChanged: (v) {
                        if (v != null) controller.setSizeGuideImage(v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(controller.sizeGuideRows.length, (i) {
                      final row = controller.sizeGuideRows[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(child: AppTextField(label: 'مقاس', controller: row.size)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'عرض', controller: row.width, keyboardType: TextInputType.number)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'طول', controller: row.length, keyboardType: TextInputType.number)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'طول من', controller: row.minHeight, keyboardType: TextInputType.number)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'طول إلى', controller: row.maxHeight, keyboardType: TextInputType.number)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'وزن من', controller: row.minWeight, keyboardType: TextInputType.number)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: AppTextField(label: 'وزن إلى', controller: row.maxWeight, keyboardType: TextInputType.number)),
                            IconButton(
                              onPressed: () => controller.removeSizeGuideRow(i),
                              icon: Icon(AppIcons.delete, color: c.error, size: AppIconSize.md),
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: 'صف مقاس',
                        icon: AppIcons.add,
                        variant: AppButtonVariant.outlined,
                        onPressed: controller.addSizeGuideRow,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
