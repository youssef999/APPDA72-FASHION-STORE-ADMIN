import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/branding_controller.dart';
import '../models/branding_model.dart';
import 'branding_style_presets.dart';

class BrandingForm extends StatelessWidget {
  const BrandingForm({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<BrandingController>(
      id: BrandingController.formId,
      builder: (ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandingStylePresets(),
            const SizedBox(height: AppSpacing.xl),
            Text('الشعار واسم البراند', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'اسم البراند',
              controller: ctrl.brandNameCtrl,
              hint: 'APPDA 72',
              onChanged: ctrl.setBrandName,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: c.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: ctrl.draft.hasLogo
                      ? AppNetworkImage(url: ctrl.draft.logoUrl, width: 120, height: 72, radius: AppRadius.md)
                      : Text('بدون شعار', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: 'رفع شعار',
                            icon: AppIcons.upload,
                            isLoading: ctrl.isUploadingLogo,
                            onPressed: ctrl.uploadLogo,
                          ),
                          if (ctrl.draft.hasLogo)
                            AppButton(
                              label: 'إزالة',
                              icon: AppIcons.delete,
                              variant: AppButtonVariant.outlined,
                              onPressed: ctrl.removeLogo,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'يفضّل PNG بخلفية شفافة (بدون مربع أبيض) ليتناسق مع الهيدر الملون',
                        style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('الألوان الأساسية', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'Primary',
              controller: ctrl.primaryCtrl,
              color: ctrl.draft.primaryColor,
              onChanged: ctrl.setPrimaryHex,
              onPick: ctrl.pickPrimarySwatch,
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'Accent',
              controller: ctrl.accentCtrl,
              color: ctrl.draft.accentColor,
              onChanged: ctrl.setAccentHex,
              onPick: ctrl.pickAccentSwatch,
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'Background',
              controller: ctrl.backgroundCtrl,
              color: ctrl.draft.backgroundColor,
              onChanged: ctrl.setBackgroundHex,
              onPick: ctrl.pickBackgroundSwatch,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('الأزرار والأيقونات والبانر', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تتحكم بلون زر التطبيق، نص الزر، الأيقونات، ونص البانر/الإطلاقات',
              style: AppTextStyles.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'لون الزر (Button)',
              controller: ctrl.buttonCtrl,
              color: ctrl.draft.buttonColor,
              onChanged: ctrl.setButtonHex,
              onPick: ctrl.pickButtonSwatch,
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'نص الزر (Button Text)',
              controller: ctrl.buttonTextCtrl,
              color: ctrl.draft.buttonTextColor,
              onChanged: ctrl.setButtonTextHex,
              onPick: ctrl.pickButtonTextSwatch,
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'الأيقونات (Icons)',
              controller: ctrl.iconCtrl,
              color: ctrl.draft.iconColor,
              onChanged: ctrl.setIconHex,
              onPick: ctrl.pickIconSwatch,
            ),
            const SizedBox(height: AppSpacing.md),
            _ColorField(
              label: 'نص البانر (Banner Text)',
              controller: ctrl.bannerTextCtrl,
              color: ctrl.draft.bannerTextColor,
              onChanged: ctrl.setBannerTextHex,
              onPick: ctrl.pickBannerTextSwatch,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('الخطوط', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              label: 'خط النصوص (Body)',
              value: ctrl.draft.bodyFont,
              items: [
                for (final font in BrandingModel.fontCatalog) AppDropdownItem(font.key, font.label),
              ],
              onChanged: ctrl.setBodyFont,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              label: 'خط العناوين (Display)',
              value: ctrl.draft.displayFont,
              items: [
                for (final font in BrandingModel.fontCatalog) AppDropdownItem(font.key, font.label),
              ],
              onChanged: ctrl.setDisplayFont,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: 'حفظ الهوية',
                  icon: AppIcons.generate,
                  isLoading: ctrl.isSaving,
                  onPressed: ctrl.save,
                ),
                AppButton(
                  label: 'استعادة الافتراضي',
                  icon: AppIcons.refresh,
                  variant: AppButtonVariant.outlined,
                  onPressed: ctrl.resetDefaults,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;

  const _ColorField({
    required this.label,
    required this.controller,
    required this.color,
    required this.onChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: label,
            controller: controller,
            hint: '#000000',
            textDirection: TextDirection.ltr,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
          ),
        ),
      ],
    );
  }
}
