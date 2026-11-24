import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/color_parser.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../categories/models/category_model.dart';
import '../controllers/product_import_controller.dart';
import '../models/import_row.dart';
import '../services/import_validator.dart';

class ImportPreviewList extends StatelessWidget {
  const ImportPreviewList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductImportController>(
      id: ProductImportController.listId,
      builder: (controller) {
        final list = controller.filteredRows;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'لا توجد صفوف في هذا الفلتر',
              style: AppTextStyles.body2.copyWith(color: context.colors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final row = list[index];
            final realIndex = controller.rows.indexOf(row);
            return _ProductReviewCard(index: realIndex, row: row, controller: controller);
          },
        );
      },
    );
  }
}

/// Full product review card: name, description, sizes, stock, image — organized for step 3.
class _ProductReviewCard extends StatelessWidget {
  final int index;
  final ImportRow row;
  final ProductImportController controller;

  const _ProductReviewCard({
    required this.index,
    required this.row,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final skipped = row.action == ImportAction.skip;
    final statusColor = skipped
        ? c.textDisabled
        : switch (row.status) {
            ImportRowStatus.ready => c.success,
            ImportRowStatus.warning => c.warning,
            ImportRowStatus.error => c.error,
          };
    final statusText = skipped
        ? 'تخطي'
        : switch (row.status) {
            ImportRowStatus.error => 'خطأ',
            ImportRowStatus.warning => 'تحذير',
            ImportRowStatus.ready => row.exists ? 'تحديث' : 'جاهز',
          };

    return Opacity(
      opacity: skipped ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: row.isValid || skipped ? c.border : c.error.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(row: row, controller: controller),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'منتج ${index + 1}',
                              style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                          _Chip(text: statusText, color: statusColor),
                          const SizedBox(width: AppSpacing.xs),
                          AppIconButton(icon: AppIcons.edit, tooltip: 'تعديل كامل', onPressed: () => controller.editRow(index)),
                          AppIconButton(
                            icon: AppIcons.delete,
                            tooltip: 'حذف',
                            color: c.error,
                            onPressed: () => controller.removeRow(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _LabeledField(
                        label: 'الاسم',
                        value: row.displayName,
                        onChanged: (v) {
                          controller.updateRowField(index, 'nameAr', v);
                          if (row.name.isEmpty) controller.updateRowField(index, 'name', v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 640;
                          final category = _CategoryCell(
                            row: row,
                            categories: controller.categories,
                            onChanged: (name) => controller.setRowCategory(index, name),
                          );
                          final price = _LabeledField(
                            label: 'السعر',
                            value: '${row.price}',
                            textDirection: TextDirection.ltr,
                            onChanged: (v) => controller.updateRowField(index, 'price', v),
                          );
                          final color = _ColorHint(row: row);
                          if (!wide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                category,
                                const SizedBox(height: AppSpacing.sm),
                                Row(children: [
                                  Expanded(child: price),
                                  const SizedBox(width: AppSpacing.sm),
                                  color,
                                ]),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: category),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(flex: 2, child: price),
                              const SizedBox(width: AppSpacing.sm),
                              color,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _SectionTitle('الوصف'),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final ar = _LabeledField(
                  label: 'الوصف بالعربي',
                  value: row.desAr,
                  maxLines: 3,
                  onChanged: (v) => controller.updateRowField(index, 'desAr', v),
                );
                final en = _LabeledField(
                  label: 'الوصف بالإنجليزي',
                  value: row.des,
                  maxLines: 3,
                  textDirection: TextDirection.ltr,
                  onChanged: (v) => controller.updateRowField(index, 'des', v),
                );
                if (!wide) {
                  return Column(children: [ar, const SizedBox(height: AppSpacing.sm), en]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ar),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: en),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const _SectionTitle('المقاسات والستوك'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'اكتب المقاس والكمية بهذا الشكل: S:5|M:3|L:2 — أو المقاسات فقط S,M,L مع كمية عامة',
              style: AppTextStyles.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                final sizes = _LabeledField(
                  label: 'المقاسات والكميات',
                  value: row.stockText,
                  hint: 'S:5|M:3|L:2',
                  textDirection: TextDirection.ltr,
                  onChanged: (v) => controller.updateRowField(index, 'stock', v),
                );
                final qty = _LabeledField(
                  label: 'الكمية العامة (بدون مقاسات)',
                  value: '${row.quantity}',
                  textDirection: TextDirection.ltr,
                  onChanged: (v) => controller.updateRowField(index, 'quantity', v),
                );
                if (!wide) {
                  return Column(children: [sizes, const SizedBox(height: AppSpacing.sm), qty]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: sizes),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: qty),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (row.resolvedSizes.isNotEmpty || row.stock.isNotEmpty)
              _SizeStockChips(row: row)
            else
              Text(
                'لا توجد مقاسات بعد — أضف مثل S:5|M:3 أو اترك الكمية العامة فقط',
                style: AppTextStyles.caption.copyWith(color: c.textDisabled),
              ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'إجمالي الستوك: ${row.totalStock}',
                style: AppTextStyles.caption.copyWith(color: c.secondary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SectionTitle('الصورة'),
            const SizedBox(height: AppSpacing.sm),
            _LabeledField(
              label: 'روابط أو أسماء ملفات (افصل بـ | )',
              value: row.images.join('|'),
              textDirection: TextDirection.ltr,
              onChanged: (v) => controller.updateRowField(index, 'images', v),
            ),
            if (row.errors.isNotEmpty || row.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final e in row.errors) _Message(text: e, color: c.error, icon: Icons.error_outline_rounded),
              for (final w in row.warnings) _Message(text: w, color: c.warning, icon: Icons.info_outline_rounded),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body2.copyWith(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextDirection? textDirection;
  final int maxLines;
  final String? hint;

  const _LabeledField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.textDirection,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          key: ValueKey('$label-$value'),
          initialValue: value,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 2 : 1,
          style: AppTextStyles.body2.copyWith(color: c.textPrimary),
          textDirection: textDirection,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.caption.copyWith(color: c.textDisabled),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: c.secondary),
            ),
          ),
          onChanged: onChanged,
          onFieldSubmitted: onChanged,
        ),
      ],
    );
  }
}

class _SizeStockChips extends StatelessWidget {
  final ImportRow row;

  const _SizeStockChips({required this.row});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = row.stock.isNotEmpty
        ? row.stock.entries.map((e) => MapEntry(e.key, e.value)).toList()
        : row.sizes.map((s) => MapEntry(s, row.quantity)).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final e in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: c.border),
            ),
            child: Text(
              row.stock.isNotEmpty ? '${e.key} · ${e.value}' : e.key,
              style: AppTextStyles.caption.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
              textDirection: TextDirection.ltr,
            ),
          ),
      ],
    );
  }
}

class _ColorHint extends StatelessWidget {
  final ImportRow row;

  const _ColorHint({required this.row});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = row.colorAr.isNotEmpty ? row.colorAr : row.color;
    if (label.isEmpty && row.colorHex.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: parseHexColor(row.colorHex) ?? c.border,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label.isEmpty ? row.colorHex : label,
            style: AppTextStyles.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final ImportRow row;
  final List<CategoryModel> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryCell({
    required this.row,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final matched = ImportValidator.matchCategory(categories, row.category);
    final value = matched?.name;
    final fileHint = row.category.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('القسم', style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        AppDropdown<String>(
          key: ValueKey('${row.productId}-cat-${value ?? fileHint}'),
          value: value,
          hint: value == null ? (fileHint.isEmpty ? 'اختر قسماً' : 'من الملف: $fileHint') : null,
          items: categories.map((c) => AppDropdownItem(c.name, c.displayName)).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final ImportRow row;
  final ProductImportController controller;

  const _Thumb({required this.row, required this.controller});

  @override
  Widget build(BuildContext context) {
    const width = 72.0;
    const height = 96.0;
    final first = row.images.isEmpty ? '' : row.images.first;
    if (first.startsWith('http') || first.isEmpty) {
      return AppNetworkImage(url: first, width: width, height: height);
    }
    final file = controller.images[ImportValidator.imageKey(first)];
    if (file == null) return AppNetworkImage(url: first, width: width, height: height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.memory(file.bytes, width: width, height: height, fit: BoxFit.cover, cacheWidth: 160),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
      );
}

class _Message extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Message({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.sm - 2, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: color))),
          ],
        ),
      );
}
