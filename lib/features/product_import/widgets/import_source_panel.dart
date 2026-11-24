import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_wrapper.dart';
import '../controllers/product_import_controller.dart';

/// Step 1: upload zone + templates + optional Google Sheets.
class ImportSourcePanel extends StatelessWidget {
  const ImportSourcePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<ProductImportController>();
    final busy = controller.isParsing || controller.isLoadingContext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.status != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: c.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              const SizedBox(width: AppIconSize.md, height: AppIconSize.md, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(child: Text(controller.status!, style: AppTextStyles.body2.copyWith(color: c.info))),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _UploadZone(busy: busy, onTap: busy ? null : controller.pickFile, isLoading: controller.isParsing),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveRow(children: [
          _SourceCard(
            icon: AppIcons.link,
            title: 'Google Sheets',
            description: 'الصق رابط الشيت بعد مشاركته "أي شخص لديه الرابط يمكنه العرض".',
            child: Column(children: [
              AppTextField(
                label: 'رابط الشيت',
                hint: 'https://docs.google.com/spreadsheets/d/...',
                controller: controller.sheetLink,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => controller.importSheet(),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: 'استيراد', expanded: true, variant: AppButtonVariant.outlined, onPressed: busy ? null : controller.importSheet),
            ]),
          ),
          _SourceCard(
            icon: AppIcons.download,
            title: 'قوالب جاهزة',
            description: 'حمّل CSV أو Excel بالأعمدة المطلوبة ثم املأه بمنتجاتك من أي منصة.',
            child: Column(children: [
              AppButton(
                label: 'تحميل قالب CSV',
                icon: AppIcons.download,
                expanded: true,
                onPressed: controller.isLoadingContext ? null : controller.downloadCsvTemplate,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'تحميل قالب Excel',
                icon: AppIcons.download,
                expanded: true,
                variant: AppButtonVariant.outlined,
                onPressed: controller.isLoadingContext ? null : controller.downloadTemplate,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'يدعم ملفات Salla / Zid / Shopify بأسماء أعمدة مختلفة — بعد الرفع تراجع ربط الأعمدة ثم تصحّح الجدول قبل الحفظ.',
          style: AppTextStyles.caption.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

class _UploadZone extends StatelessWidget {
  final bool busy;
  final bool isLoading;
  final VoidCallback? onTap;

  const _UploadZone({required this.busy, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.secondary.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: isLoading
                    ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(AppIcons.upload, color: c.secondary, size: AppIconSize.xl),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('اضغط لرفع ملف Excel أو CSV', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'xlsx · csv · docx · pdf — يتم اكتشاف الأعمدة تلقائياً ثم تراجع الربط يدوياً',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'اختيار ملف', icon: AppIcons.upload, isLoading: isLoading, onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _SourceCard({required this.icon, required this.title, required this.description, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, color: c.secondary, size: AppIconSize.lg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 48,
            child: Text(description, style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
