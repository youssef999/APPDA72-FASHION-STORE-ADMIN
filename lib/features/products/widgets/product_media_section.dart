import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/color_parser.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_image_picker.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/product_form_controller.dart';

class ProductColorsSection extends StatelessWidget {
  const ProductColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ProductFormController>(
      id: ProductFormController.colorsId,
      builder: (controller) => AppCard(
        title: 'اللون',
        trailing: Text('لكل لون منتج مستقل بنفس groupId', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(controller.colors.length, (index) {
              final row = controller.colors[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: parseHexColor(row.hex.text) ?? c.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border, width: 2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: AppTextField(label: 'عربي', controller: row.nameAr)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: AppTextField(label: 'English', controller: row.name, textDirection: TextDirection.ltr)),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 110,
                      child: AppTextField(
                        label: 'HEX',
                        controller: row.hex,
                        textDirection: TextDirection.ltr,
                        onChanged: (_) => controller.refreshColors(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppIconButton(icon: AppIcons.delete, color: c.error, onPressed: () => controller.removeColor(index)),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(label: 'إضافة لون', icon: AppIcons.add, variant: AppButtonVariant.ghost, onPressed: controller.addColor),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImagesSection extends StatelessWidget {
  const ProductImagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductFormController>(
      id: ProductFormController.imagesId,
      builder: (controller) => AppCard(
        title: 'الصور',
        child: AppImagePicker(
          urls: controller.imageUrls,
          isUploading: controller.isUploading,
          onUpload: controller.uploadImages,
          onAddUrl: controller.addImageUrl,
          onRemove: controller.removeImage,
          onReorder: controller.reorderImages,
        ),
      ),
    );
  }
}
