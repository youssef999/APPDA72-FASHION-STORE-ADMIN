import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/categories_controller.dart';

class CategoryFormDialog extends StatelessWidget {
  const CategoryFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<CategoriesController>();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(controller.editing == null ? 'قسم جديد' : 'تعديل القسم',
                  style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'الاسم بالعربي', controller: controller.nameArController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'الاسم بالإنجليزي (يُربط به المنتجات)',
                controller: controller.nameController,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'ترتيب الظهور',
                controller: controller.orderController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) controller.onImageChanged();
                },
                child: AppTextField(
                  label: 'رابط الصورة',
                  hint: 'https://...',
                  icon: AppIcons.image,
                  controller: controller.imageController,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => controller.onImageChanged(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GetBuilder<CategoriesController>(
                id: CategoriesController.formId,
                builder: (controller) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'رفع صورة من الجهاز',
                      icon: AppIcons.upload,
                      variant: AppButtonVariant.outlined,
                      isLoading: controller.isUploading,
                      onPressed: controller.uploadImage,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: AppNetworkImage(url: controller.imageController.text.trim(), width: 160, height: 110),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'إلغاء',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(label: 'حفظ', isLoading: controller.isSaving, onPressed: controller.save),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
