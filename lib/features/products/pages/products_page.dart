import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.products,
      title: 'المنتجات',
      body: GetBuilder<ProductsController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'كتالوج المنتجات',
                subtitle: '${controller.products.length} منتج',
                actions: [
                  AppSearchField(hint: 'الاسم، الماركة أو الرقم', onChanged: controller.search, width: 240),
                  SizedBox(
                    width: 190,
                    child: AppDropdown<String?>(
                      hint: 'كل الأقسام',
                      value: controller.categoryFilter,
                      onChanged: controller.setCategory,
                      items: [
                        const AppDropdownItem<String?>(null, 'كل الأقسام'),
                        ...controller.categories.map((c) => AppDropdownItem<String?>(c.name, c.nameAr)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: AppDropdown<StockFilter>(
                      value: controller.stockFilter,
                      onChanged: (value) => controller.setStockFilter(value ?? StockFilter.all),
                      items: const [
                        AppDropdownItem(StockFilter.all, 'كل المخزون'),
                        AppDropdownItem(StockFilter.low, 'مخزون منخفض'),
                        AppDropdownItem(StockFilter.out, 'نفد المخزون'),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'استيراد جماعي',
                    icon: AppIcons.upload,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Get.offAllNamed(AppRoutes.productImport),
                  ),
                  AppButton(label: 'منتج جديد', icon: AppIcons.add, onPressed: controller.openForm),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _body(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ProductsController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<ProductsController>(
      id: ProductsController.gridId,
      builder: (controller) {
        final products = controller.filtered;
        if (products.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.products,
            title: 'لا توجد منتجات',
            message: 'أضف منتجًا يدويًا أو استخدم الاستيراد الجماعي من الشريط أعلاه',
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 390,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        );
      },
    );
  }
}
