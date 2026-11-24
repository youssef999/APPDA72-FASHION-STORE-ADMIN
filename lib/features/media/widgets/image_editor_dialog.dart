import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../controllers/image_editor_controller.dart';
import 'image_editor_tools.dart';

class ImageEditorDialog extends StatelessWidget {
  const ImageEditorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: GetBuilder<ImageEditorController>(
          builder: (controller) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تجهيز الصورة', style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
                          Text(
                            controller.queue.length > 1
                                ? 'صورة ${controller.index + 1} من ${controller.queue.length} • ${controller.fileName}'
                                : controller.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(icon: AppIcons.close, tooltip: 'إغلاق', onPressed: controller.isBusy ? null : controller.close),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _Canvas(controller: controller)),
                const SizedBox(height: AppSpacing.md),
                ImageEditorTools(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  final ImageEditorController controller;

  const _Canvas({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bytes = controller.current;
    Widget child;
    if (controller.isPreparing) {
      child = const AppLoader();
    } else if (bytes == null) {
      child = const AppEmptyState(icon: AppIcons.image, title: 'تعذر فتح الصورة');
    } else if (controller.isCropping) {
      child = Crop(
        image: bytes,
        controller: controller.cropController,
        aspectRatio: controller.cropRatio,
        onCropped: controller.onCropped,
        baseColor: c.background,
        maskColor: c.primary.withValues(alpha: 0.55),
        interactive: true,
        progressIndicator: const AppLoader(),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
          if (controller.isRemovingBg || controller.isUploading)
            ColoredBox(
              color: c.card.withValues(alpha: 0.75),
              child: GetBuilder<ImageEditorController>(
                id: ImageEditorController.toolsId,
                builder: (controller) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2.5),
                    const SizedBox(height: AppSpacing.md),
                    Text(_busyLabel(controller), textAlign: TextAlign.center, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }

  String _busyLabel(ImageEditorController controller) {
    if (controller.isUploading) return 'جاري الضغط والرفع...';
    final progress = controller.modelProgress;
    if (progress != null && progress < 100) return 'تحميل نموذج الذكاء الاصطناعي لأول مرة $progress%\nيتم مرة واحدة فقط';
    return 'جاري تفريغ الخلفية وجعلها بيضاء...\nقد يستغرق تحميل النموذج دقيقة في المرة الأولى فقط';
  }
}
