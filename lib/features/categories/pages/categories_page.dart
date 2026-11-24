import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/categories_controller.dart';
import '../models/category_model.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.categories,
      title: 'الأقسام',
      body: GetBuilder<CategoriesController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'أقسام المتجر',
                subtitle: '${controller.categories.length} قسم • الترتيب هنا هو ترتيب الظهور في التطبيق',
                actions: [AppButton(label: 'قسم جديد', icon: AppIcons.add, onPressed: controller.openForm)],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _body(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(CategoriesController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    if (controller.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppEmptyState(
              icon: AppIcons.categories,
              title: 'لا توجد أقسام بعد',
              message: 'ابدأ بقسم واحد (مثل عبايات) ثم أضف المنتجات تحته',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'إنشاء أول قسم', icon: AppIcons.add, onPressed: controller.openForm),
          ],
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 250,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: controller.categories.length,
      itemBuilder: (context, index) => _CategoryTile(category: controller.categories[index]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<CategoriesController>();
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => AppNetworkImage(url: category.image, width: box.maxWidth, height: box.maxHeight),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
                    Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('#${category.order ?? '—'}', style: AppTextStyles.caption.copyWith(color: c.secondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'تعديل',
                  icon: AppIcons.edit,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => controller.openForm(category),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(icon: AppIcons.delete, color: c.error, tooltip: 'حذف', onPressed: () => controller.delete(category)),
            ],
          ),
        ],
      ),
    );
  }
}
