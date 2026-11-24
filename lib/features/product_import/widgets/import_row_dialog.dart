import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../products/widgets/product_info_section.dart';
import '../controllers/product_import_controller.dart';
import '../services/import_validator.dart';

/// Fixes one imported row before saving.
class ImportRowDialog extends StatelessWidget {
  static const String id = 'import_row_dialog';

  const ImportRowDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<ProductImportController>();
    final f = controller.fields;
    const gap = SizedBox(height: AppSpacing.md);
    const ltr = TextDirection.ltr;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text('تعديل المنتج قبل الحفظ', style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(children: [
                  FieldPair(
                    first: AppTextField(label: 'الاسم بالعربي', controller: f['nameAr']!),
                    second: AppTextField(label: 'الاسم بالإنجليزي', controller: f['name']!, textDirection: ltr),
                  ),
                  gap,
                  FieldPair(
                    first: AppTextField(label: 'الوصف بالعربي', controller: f['desAr']!, maxLines: 3),
                    second: AppTextField(label: 'الوصف بالإنجليزي', controller: f['des']!, maxLines: 3, textDirection: ltr),
                  ),
                  gap,
                  GetBuilder<ProductImportController>(
                    id: id,
                    builder: (controller) {
                      final matched = ImportValidator.matchCategory(
                        controller.categories,
                        controller.editingCategory ?? '',
                      );
                      return AppDropdown<String>(
                        label: 'القسم',
                        hint: matched == null && (controller.editingCategory ?? '').isNotEmpty
                            ? 'من الملف: ${controller.editingCategory}'
                            : 'اختر القسم',
                        value: matched?.name,
                        onChanged: controller.setEditingCategory,
                        items: controller.categories.map((cat) => AppDropdownItem(cat.name, cat.displayName)).toList(),
                      );
                    },
                  ),
                  gap,
                  FieldPair(
                    first: AppTextField(label: 'السعر', controller: f['price']!, keyboardType: TextInputType.number),
                    second: AppTextField(label: 'السعر قبل الخصم (0 = بدون)', controller: f['oldPrice']!, keyboardType: TextInputType.number),
                  ),
                  gap,
                  FieldPair(
                    first: AppTextField(label: 'اللون بالعربي', controller: f['colorAr']!),
                    second: FieldPair(
                      first: AppTextField(label: 'Color', controller: f['color']!, textDirection: ltr),
                      second: AppTextField(label: 'HEX', controller: f['colorHex']!, textDirection: ltr),
                    ),
                  ),
                  gap,
                  FieldPair(
                    first: AppTextField(label: 'المقاسات والكمية (S:5|M:3)', controller: f['stock']!, textDirection: ltr),
                    second: AppTextField(label: 'الكمية (بدون مقاسات)', controller: f['quant']!, keyboardType: TextInputType.number),
                  ),
                  gap,
                  AppTextField(label: 'رقم المجموعة (groupId)', controller: f['groupId']!, textDirection: ltr),
                  gap,
                  AppTextField(label: 'الصور (رابط أو اسم ملف في كل سطر)', controller: f['images']!, maxLines: 3, textDirection: ltr),
                  gap,
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                AppButton(label: 'إلغاء', variant: AppButtonVariant.outlined, onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.sm),
                AppButton(label: 'تطبيق', onPressed: controller.saveEdit),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
