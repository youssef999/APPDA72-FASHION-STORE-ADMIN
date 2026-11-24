import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../../products/models/product_model.dart';
import '../controllers/best_sellers_controller.dart';

class BestSellersPage extends StatelessWidget {
  const BestSellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.bestSellers,
      title: 'الأفضل مبيعاً',
      body: GetBuilder<BestSellersController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'ترتيب المبيعات وتثبيت المنتجات',
                subtitle: 'يظهر في التطبيق تحت العروض — المثبّت أولاً ثم حسب عدد المبيعات',
                actions: [
                  AppSearchField(hint: 'بحث', onChanged: controller.search),
                  AppButton(
                    label: 'مزامنة الطلبات',
                    icon: AppIcons.refresh,
                    variant: AppButtonVariant.outlined,
                    isLoading: controller.isSyncingSold,
                    onPressed: () => controller.syncSoldCounts(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilterChip(
                  label: const Text('المثبّت فقط'),
                  selected: controller.pinnedOnly,
                  onSelected: controller.setPinnedOnly,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppCard(
                  expand: true,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _body(controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BestSellersController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<BestSellersController>(
      id: BestSellersController.listId,
      builder: (controller) {
        final items = controller.filtered;
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: AppIcons.bestSeller,
            title: 'لا توجد منتجات',
            message: 'ثبّت منتجات أو انتظر اكتمال الطلبات لتجميع المبيعات',
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = items[index];
            final c = context.colors;
            return ListTile(
              leading: _thumb(product, c),
              title: Text(product.displayName, style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
              subtitle: Text(
                '${product.catAr.isNotEmpty ? product.catAr : product.cat} · مبيعات: ${controller.soldCountOf(product)}',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
              trailing: IconButton(
                tooltip: product.isBestSeller ? 'إزالة التثبيت' : 'تثبيت',
                onPressed: () => controller.togglePin(product),
                icon: Icon(
                  product.isBestSeller ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  color: product.isBestSeller ? c.primary : c.textSecondary,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _thumb(ProductModel product, AppPalette c) {
    final url = product.thumbnail.isNotEmpty ? product.thumbnail : product.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url.isEmpty
            ? ColoredBox(color: c.border, child: Icon(AppIcons.products, color: c.textSecondary, size: AppIconSize.md))
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: c.border)),
      ),
    );
  }
}
