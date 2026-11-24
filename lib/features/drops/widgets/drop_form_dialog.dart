import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/drops_controller.dart';
import '../models/drop_model.dart';

class DropFormDialog extends StatelessWidget {
  const DropFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: GetBuilder<DropsController>(
          id: DropsController.formId,
          builder: (controller) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(controller.editing == null ? 'إطلاق جديد' : 'تعديل الإطلاق', style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: AppTextField(label: 'العنوان EN', controller: controller.title)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: AppTextField(label: 'العنوان AR', controller: controller.titleAr)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(child: AppTextField(label: 'الوصف EN', controller: controller.subtitle)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: AppTextField(label: 'الوصف AR', controller: controller.subtitleAr)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppDropdown<DropStatus>(
                          label: 'الحالة',
                          value: controller.status,
                          items: DropStatus.values
                              .map((s) => AppDropdownItem(s, DropModel.statusLabel(s)))
                              .toList(),
                          onChanged: controller.setStatus,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'إطلاق التطبيق',
                                value: controller.launchAt,
                                onPick: controller.setLaunchAt,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _DateField(
                                label: 'فتح عام (+2س افتراضي)',
                                value: controller.webUnlockAt,
                                onPick: controller.setWebUnlockAt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'يفتح في التطبيق: ${Formatters.dateTime(controller.launchAt)} · يصبح عاماً: ${Formatters.dateTime(controller.webUnlockAt)}',
                          style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            if (controller.coverImage.isNotEmpty)
                              AppNetworkImage(url: controller.coverImage, width: 72, height: 90),
                            const SizedBox(width: AppSpacing.md),
                            AppButton(
                              label: 'غلاف الإطلاق',
                              icon: AppIcons.upload,
                              variant: AppButtonVariant.outlined,
                              isLoading: controller.isUploadingCover,
                              onPressed: controller.uploadCover,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('المنتجات', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                        const SizedBox(height: AppSpacing.sm),
                        ...controller.products.map((p) {
                          final selected = controller.selectedProductIds.contains(p.productId);
                          return CheckboxListTile(
                            dense: true,
                            value: selected,
                            onChanged: (_) => controller.toggleProduct(p.productId),
                            title: Text(p.displayName, style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
                            subtitle: Text(p.productId, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(label: 'إلغاء', variant: AppButtonVariant.outlined, onPressed: Get.back),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(label: 'حفظ', isLoading: controller.isSaving, onPressed: controller.save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date == null) return;
        if (!context.mounted) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(AppIcons.calendar, color: c.textSecondary),
        ),
        child: Text(Formatters.dateTime(value), style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
      ),
    );
  }
}
