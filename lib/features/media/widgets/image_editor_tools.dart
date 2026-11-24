import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../controllers/image_editor_controller.dart';

/// Bottom bar of the editor: crop presets while cropping, otherwise edit and upload actions.
class ImageEditorTools extends StatelessWidget {
  final ImageEditorController controller;

  const ImageEditorTools({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isCropping) return _CropBar(controller: controller);
    final disabled = controller.isBusy || controller.current == null;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(label: 'قص', icon: AppIcons.crop, variant: AppButtonVariant.outlined, onPressed: disabled ? null : controller.startCrop),
            AppButton(
              label: 'تفريغ الخلفية',
              icon: AppIcons.magic,
              variant: AppButtonVariant.outlined,
              onPressed: disabled ? null : controller.removeBackground,
            ),
            if (controller.canUndo)
              AppButton(label: 'تراجع', icon: AppIcons.undo, variant: AppButtonVariant.ghost, onPressed: disabled ? null : controller.undo),
          ],
        ),
        const _SizeBadge(),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (controller.queue.length > 1) ...[
              AppButton(label: 'تخطي', variant: AppButtonVariant.ghost, onPressed: disabled ? null : controller.skip),
              AppButton(
                label: 'رفع الكل كما هو',
                variant: AppButtonVariant.outlined,
                onPressed: disabled ? null : controller.uploadRemaining,
              ),
            ],
            AppButton(
              label: controller.isLast ? 'رفع' : 'رفع والتالي',
              icon: AppIcons.upload,
              isLoading: controller.isUploading,
              onPressed: disabled ? null : controller.uploadCurrent,
            ),
          ],
        ),
      ],
    );
  }
}

class _SizeBadge extends StatelessWidget {
  const _SizeBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<ImageEditorController>(
      id: ImageEditorController.previewId,
      builder: (controller) {
        final after = controller.compressedSize;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: c.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            after == null
                ? 'جاري حساب الحجم...'
                : '${ImageEditorController.formatBytes(controller.originalSize)} → ${ImageEditorController.formatBytes(after)}',
            textDirection: TextDirection.ltr,
            style: AppTextStyles.caption.copyWith(color: c.success),
          ),
        );
      },
    );
  }
}

class _CropBar extends StatelessWidget {
  final ImageEditorController controller;

  const _CropBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const presets = <String, double?>{'4:5': 0.8, '1:1': 1, 'حر': null};
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GetBuilder<ImageEditorController>(
          id: ImageEditorController.toolsId,
          builder: (controller) => Wrap(
            spacing: AppSpacing.sm,
            children: presets.entries.map((e) {
              final selected = controller.cropRatio == e.value;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                selectedColor: c.primary,
                label: Text(e.key, style: AppTextStyles.caption.copyWith(color: selected ? c.onPrimary : c.textPrimary)),
                onSelected: (_) => controller.setCropRatio(e.value),
              );
            }).toList(),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            AppButton(label: 'إلغاء', variant: AppButtonVariant.outlined, onPressed: controller.cancelCrop),
            AppButton(label: 'تطبيق القص', icon: AppIcons.crop, onPressed: controller.applyCrop),
          ],
        ),
      ],
    );
  }
}
