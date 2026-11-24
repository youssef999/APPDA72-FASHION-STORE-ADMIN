import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/product_import_controller.dart';
import '../widgets/import_mapping_panel.dart';
import '../widgets/import_preview_list.dart';
import '../widgets/import_source_panel.dart';
import '../widgets/import_toolbar.dart';

class ProductImportPage extends StatelessWidget {
  const ProductImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.productImport,
      title: 'المنتجات',
      body: GetBuilder<ProductImportController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'استيراد جماعي ذكي',
                subtitle: switch (controller.phase) {
                  ImportPhase.upload => 'ارفع Excel أو CSV من Salla / Zid / Shopify أو القالب الجاهز',
                  ImportPhase.mapping => 'راجع ربط أعمدة الملف مع حقول Firestore',
                  ImportPhase.preview => 'صحّح الصفوف ثم احفظ على المتجر',
                  ImportPhase.saving => 'جاري الرفع…',
                  ImportPhase.done => 'اكتمل الاستيراد',
                },
                actions: [
                  AppButton(
                    label: 'رجوع للمنتجات',
                    variant: AppButtonVariant.outlined,
                    onPressed: controller.phase == ImportPhase.saving ? null : () => Get.offAllNamed(AppRoutes.products),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (controller.phase != ImportPhase.saving && controller.phase != ImportPhase.done) ...[
                _Stepper(phase: controller.phase),
                const SizedBox(height: AppSpacing.lg),
              ],
              Expanded(child: _body(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ProductImportController controller) => switch (controller.phase) {
        ImportPhase.upload => controller.isLoadingContext
            ? const AppLoader()
            : const SingleChildScrollView(child: ImportSourcePanel()),
        ImportPhase.mapping => const ImportMappingPanel(),
        ImportPhase.preview => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ImportToolbar(), SizedBox(height: AppSpacing.md), Expanded(child: ImportPreviewList())],
          ),
        ImportPhase.saving => const _SavingView(),
        ImportPhase.done => _DoneView(count: controller.savedCount, onAgain: controller.reset),
      };
}

class _Stepper extends StatelessWidget {
  final ImportPhase phase;

  const _Stepper({required this.phase});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = const ['رفع الملف', 'ربط الأعمدة', 'مراجعة وحفظ'];
    final active = switch (phase) {
      ImportPhase.upload => 0,
      ImportPhase.mapping => 1,
      _ => 2,
    };
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: i <= active ? c.secondary : c.divider)),
          _StepDot(index: i + 1, label: steps[i], active: i <= active, current: i == active),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final bool current;

  const _StepDot({required this.index, required this.label, required this.active, required this.current});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.secondary : c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: active ? c.secondary : c.border),
          ),
          child: Text('$index', style: AppTextStyles.caption.copyWith(color: active ? Colors.white : c.textSecondary)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption.copyWith(color: current ? c.textPrimary : c.textSecondary)),
      ],
    );
  }
}

class _SavingView extends StatelessWidget {
  const _SavingView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AppCard(
          child: GetBuilder<ProductImportController>(
            id: ProductImportController.progressId,
            builder: (controller) {
              final total = controller.progressTotal;
              final value = total == 0 ? null : controller.progressDone / total;
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Text(controller.progressLabel, style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(value: value, minHeight: 10, color: c.secondary, backgroundColor: c.divider),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${controller.progressDone} / $total', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Text('لا تغلق الصفحة حتى ينتهي الحفظ', style: AppTextStyles.caption.copyWith(color: c.warning)),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  final int count;
  final VoidCallback onAgain;

  const _DoneView({required this.count, required this.onAgain});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline_rounded, size: 72, color: c.success),
        const SizedBox(height: AppSpacing.md),
        Text('تم حفظ $count منتج', style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Text('ظهرت المنتجات في التطبيق مباشرة', style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(spacing: AppSpacing.sm, children: [
          AppButton(label: 'استيراد ملف آخر', icon: AppIcons.upload, variant: AppButtonVariant.outlined, onPressed: onAgain),
          AppButton(label: 'عرض المنتجات', onPressed: () => Get.offAllNamed(AppRoutes.products)),
        ]),
      ]),
    );
  }
}
