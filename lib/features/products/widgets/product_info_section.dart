import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/product_form_controller.dart';

/// Two fields side by side on wide cards, stacked on narrow ones.
class FieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const FieldPair({super.key, required this.first, required this.second});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => box.maxWidth < 420
            ? Column(children: [first, const SizedBox(height: AppSpacing.md), second])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: second),
                ],
              ),
      );
}

class ProductInfoSection extends StatelessWidget {
  final ProductFormController controller;

  const ProductInfoSection({super.key, required this.controller});

  static const int _descriptionLines = 6;
  static const int _descriptionMaxLines = 14;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.md);
    return AppCard(
      title: 'بيانات المنتج',
      child: Column(
        children: [
          FieldPair(
            first: AppTextField(label: 'الاسم بالعربي', controller: controller.nameAr),
            second: AppTextField(label: 'الاسم بالإنجليزي', controller: controller.name, textDirection: TextDirection.ltr),
          ),
          gap,
          AppTextField(
            label: 'الوصف بالعربي',
            controller: controller.desAr,
            minLines: _descriptionLines,
            maxLines: _descriptionMaxLines,
            keyboardType: TextInputType.multiline,
          ),
          gap,
          AppTextField(
            label: 'الوصف بالإنجليزي',
            controller: controller.des,
            minLines: _descriptionLines,
            maxLines: _descriptionMaxLines,
            keyboardType: TextInputType.multiline,
            textDirection: TextDirection.ltr,
          ),
          gap,
          FieldPair(
            first: AppDropdown<String>(
              label: 'القسم',
              hint: 'اختر القسم',
              value: controller.selectedCategory,
              onChanged: controller.selectCategory,
              items: controller.categories.map((c) => AppDropdownItem(c.name, c.displayName)).toList(),
            ),
            second: AppTextField(
              label: 'رقم المنتج (productid)',
              controller: controller.productId,
              readOnly: controller.isEditing,
              textDirection: TextDirection.ltr,
            ),
          ),
          gap,
          AppTextField(
            label: 'رقم المجموعة (groupId)',
            hint: 'نفس الرقم لكل ألوان الموديل',
            controller: controller.groupId,
            textDirection: TextDirection.ltr,
          ),
          gap,
          AppTextField(
            label: 'وسم القماش (fabricTag)',
            hint: 'اختياري — مثال: crepe, chiffon',
            controller: controller.fabricTag,
            textDirection: TextDirection.ltr,
          ),
          gap,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('تثبيت في الأفضل مبيعاً', style: AppTextStyles.body1.copyWith(color: context.colors.textPrimary)),
            subtitle: Text(
              controller.isEditing ? 'المبيعات المسجّلة: ${controller.soldCount}' : 'يظهر في سكشن الأفضل مبيعاً تحت العروض',
              style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
            ),
            value: controller.isBestSeller,
            onChanged: controller.toggleBestSeller,
          ),
        ],
      ),
    );
  }
}
