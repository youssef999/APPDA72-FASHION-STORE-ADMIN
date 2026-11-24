import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../controllers/product_import_controller.dart';
import '../parsers/column_mapper.dart';

/// Step 2: review / adjust how file headers map to Firestore fields.
class ImportMappingPanel extends StatelessWidget {
  const ImportMappingPanel({super.key});

  static const _skip = '__skip__';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Rebuild on any controller update (not only mappingId) so the list never stays blank.
    return GetBuilder<ProductImportController>(
      builder: (controller) {
        final headers = controller.fileHeaders;
        final items = <AppDropdownItem<String>>[
          const AppDropdownItem(_skip, '— تخطي / افتراضي —'),
          ...headers.map((h) => AppDropdownItem(h, h)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ربط أعمدة الملف', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'الملف "${controller.sourceName}" — ${controller.parsedSheet?.dataRows.length ?? 0} صف. '
                    'عدّل الربط إن كانت أسماء الأعمدة مختلفة (Salla / Zid / Shopify).',
                    style: AppTextStyles.body2.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: c.border),
                  boxShadow: [BoxShadow(color: c.shadow, blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: ImportColumns.template.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 4),
                  itemBuilder: (_, i) {
                    final field = ImportColumns.template[i];
                    final current = controller.columnMapping[field];
                    final value = current == null || current.isEmpty
                        ? _skip
                        : (headers.contains(current) ? current : _skip);
                    return AppDropdown<String>(
                      key: ValueKey('$field-$value'),
                      label: ImportColumns.labelsAr[field] ?? field,
                      value: value,
                      items: items,
                      onChanged: (v) => controller.setColumnMapping(field, v == null || v == _skip ? null : v),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                AppButton(label: 'رجوع', icon: AppIcons.undo, variant: AppButtonVariant.outlined, onPressed: controller.backToUpload),
                AppButton(label: 'متابعة للمراجعة', icon: AppIcons.upload, onPressed: controller.confirmMapping),
              ],
            ),
          ],
        );
      },
    );
  }
}
