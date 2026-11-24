import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/product_form_controller.dart';
import '../widgets/product_info_section.dart';
import '../widgets/product_look_section.dart';
import '../widgets/product_media_section.dart';
import '../widgets/product_size_guide_section.dart';
import '../widgets/product_stock_section.dart';

class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AdminScaffold(
      route: AppRoutes.productForm,
      title: 'المنتجات',
      body: GetBuilder<ProductFormController>(
        builder: (controller) {
          if (controller.isLoading) return const AppLoader();
          const gap = SizedBox(height: AppSpacing.lg);
          final main = <Widget>[
            ProductInfoSection(controller: controller),
            gap,
            const ProductColorsSection(),
            gap,
            AppCard(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('خيارات متقدمة', style: AppTextStyles.body1.copyWith(color: colors.textPrimary)),
                subtitle: Text(
                  'دليل المقاسات وتسوّق الإطلالة — اختياري لمعظم المنتجات',
                  style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                ),
                value: controller.showAdvanced,
                onChanged: controller.toggleAdvanced,
              ),
            ),
            if (controller.showAdvanced) ...[
              gap,
              const ProductSizeGuideSection(),
              gap,
              const ProductLookSection(),
            ],
          ];
          const side = [ProductStockSection(), gap, ProductImagesSection()];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageToolbar(
                  title: controller.isEditing ? 'تعديل المنتج' : 'منتج جديد',
                  subtitle: 'الأساسيات أولاً: الاسم · السعر · المخزون · الصور',
                  actions: [
                    AppButton(
                      label: 'إلغاء',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Get.offNamed(AppRoutes.products),
                    ),
                    AppButton(label: 'حفظ المنتج', isLoading: controller.isSaving, onPressed: controller.save),
                  ],
                ),
                gap,
                if (Breakpoints.isDesktop(context))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Column(children: main)),
                      const SizedBox(width: AppSpacing.lg),
                      const Expanded(flex: 2, child: Column(children: side)),
                    ],
                  )
                else
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...main, gap, ...side]),
              ],
            ),
          );
        },
      ),
    );
  }
}
