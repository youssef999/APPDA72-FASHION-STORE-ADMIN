import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../app_network_image.dart';
import '../buttons/app_button.dart';

/// Reorderable image strip; the first image is the main one. Uploading itself is done by the caller.
class AppImagePicker extends StatelessWidget {
  final List<String> urls;
  final VoidCallback? onUpload;
  final ValueChanged<String> onAddUrl;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool isUploading;

  static const double _tileWidth = 104;
  static const double _tileHeight = 130;

  const AppImagePicker({
    super.key,
    required this.urls,
    required this.onUpload,
    required this.onAddUrl,
    required this.onRemove,
    required this.onReorder,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _tileHeight,
          child: Row(
            children: [
              _AddTile(isUploading: isUploading, onTap: onUpload),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: urls.isEmpty
                    ? Center(
                        child: Text('لا توجد صور بعد', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                      )
                    : ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        buildDefaultDragHandles: false,
                        itemCount: urls.length,
                        onReorderItem: onReorder,
                        itemBuilder: (context, index) => ReorderableDragStartListener(
                          key: ValueKey(urls[index]),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                            child: _ImageTile(url: urls[index], isMain: index == 0, onRemove: () => onRemove(urls[index])),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                'اسحب لترتيب الصور • الأولى هي الرئيسية • تُضغط تلقائياً قبل الرفع',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
            ),
            AppButton(label: 'إضافة رابط', icon: AppIcons.link, variant: AppButtonVariant.ghost, onPressed: () => _askUrl(context)),
          ],
        ),
      ],
    );
  }

  Future<void> _askUrl(BuildContext context) async {
    final field = TextEditingController();
    final url = await Get.dialog<String>(AlertDialog(
      title: Text('إضافة صورة برابط', style: AppTextStyles.h5),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: field,
          autofocus: true,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'https://...'),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
      ),
      actions: [
        AppButton(label: 'إلغاء', variant: AppButtonVariant.outlined, onPressed: () => Get.back()),
        AppButton(label: 'إضافة', onPressed: () => Get.back(result: field.text.trim())),
      ],
    ));
    field.dispose();
    if (url != null && url.isNotEmpty) onAddUrl(url);
  }
}

class _AddTile extends StatelessWidget {
  final bool isUploading;
  final VoidCallback? onTap;

  const _AddTile({required this.isUploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: AppImagePicker._tileWidth,
        decoration: BoxDecoration(
          color: c.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.secondary.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUploading)
              const SizedBox(width: AppIconSize.lg, height: AppIconSize.lg, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(AppIcons.upload, color: c.secondary, size: AppIconSize.lg),
            const SizedBox(height: AppSpacing.sm),
            Text(isUploading ? 'جاري الرفع' : 'رفع صور', style: AppTextStyles.caption.copyWith(color: c.secondary)),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onRemove;

  const _ImageTile({required this.url, required this.isMain, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        AppNetworkImage(url: url, width: AppImagePicker._tileWidth, height: AppImagePicker._tileHeight),
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: Material(
            color: c.card,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(AppIcons.close, size: AppIconSize.sm, color: c.error),
              ),
            ),
          ),
        ),
        if (isMain)
          PositionedDirectional(
            bottom: AppSpacing.xs,
            start: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Text('رئيسية', style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
