import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../controllers/product_import_controller.dart';
import '../models/import_row.dart';
import '../services/import_validator.dart';

/// Step 3 header: status filters, image matching, bulk actions and save.
class ImportToolbar extends StatelessWidget {
  const ImportToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ProductImportController>(
      builder: (controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: 'الكل',
                value: controller.rows.length,
                color: c.textPrimary,
                selected: controller.previewFilter == PreviewFilter.all,
                onTap: () => controller.setPreviewFilter(PreviewFilter.all),
              ),
              _FilterChip(
                label: 'جاهز',
                value: controller.readyCount,
                color: c.success,
                selected: controller.previewFilter == PreviewFilter.ready,
                onTap: () => controller.setPreviewFilter(PreviewFilter.ready),
              ),
              _FilterChip(
                label: 'تحذيرات',
                value: controller.warningCount,
                color: c.warning,
                selected: controller.previewFilter == PreviewFilter.warning,
                onTap: () => controller.setPreviewFilter(PreviewFilter.warning),
              ),
              _FilterChip(
                label: 'أخطاء',
                value: controller.errorCount,
                color: c.error,
                selected: controller.previewFilter == PreviewFilter.error,
                onTap: () => controller.setPreviewFilter(PreviewFilter.error),
              ),
              if (controller.existingCount > 0) _Count(label: 'موجود مسبقاً', value: controller.existingCount, color: c.info),
              if (controller.neededImages > 0)
                _Count(label: 'صور مطابقة', value: controller.matchedImages, total: controller.neededImages, color: c.secondary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                label: controller.parsedSheet != null ? 'تعديل الربط' : 'ملف آخر',
                icon: AppIcons.undo,
                variant: AppButtonVariant.ghost,
                onPressed: controller.parsedSheet != null ? controller.backToMapping : controller.reset,
              ),
              if (controller.neededImages > 0)
                AppButton(label: 'رفع صور المنتجات', icon: AppIcons.image, variant: AppButtonVariant.outlined, onPressed: controller.pickImages),
              if (controller.existingCount > 0) ...[
                AppButton(
                  label: 'تحديث كل الموجود',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.setExistingAction(ImportAction.update),
                ),
                AppButton(
                  label: 'تخطي كل الموجود',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.setExistingAction(ImportAction.skip),
                ),
              ],
              if (controller.categories.isNotEmpty &&
                  controller.rows.any((r) => ImportValidator.matchCategory(controller.categories, r.category) == null))
                SizedBox(
                  width: 220,
                  child: AppDropdown<String>(
                    hint: 'تعيين قسم للكل بدون قسم',
                    items: controller.categories.map((cat) => AppDropdownItem(cat.name, cat.displayName)).toList(),
                    onChanged: controller.applyCategoryToUnmatched,
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(AppIcons.magic, size: AppIconSize.md, color: c.secondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('تفريغ خلفية الصور تلقائياً', style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
                    Switch(value: controller.removeBackground, onChanged: controller.toggleRemoveBackground),
                  ]),
                ),
              ),
              AppButton(
                label: 'حفظ ${controller.saveReadyCount} منتج',
                icon: AppIcons.upload,
                onPressed: controller.saveReadyCount == 0 ? null : controller.commit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? color : color.withValues(alpha: 0.25)),
          ),
          child: Text('$label: $value', style: AppTextStyles.caption.copyWith(color: color)),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final int? total;
  final Color color;

  const _Count({required this.label, required this.value, required this.color, this.total});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Text(
          total == null ? '$label: $value' : '$label: $value / $total',
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      );
}
