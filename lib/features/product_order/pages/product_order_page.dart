import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../../products/models/product_model.dart';
import '../controllers/product_order_controller.dart';

class ProductOrderPage extends StatelessWidget {
  const ProductOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.productOrder,
      title: 'ترتيب العرض',
      body: GetBuilder<ProductOrderController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'ترتيب المنتجات في التطبيق',
                subtitle: 'اكتب رقم الترتيب أو اسحب — يظهر في الهوم وداخل القسم · عدد الطلبات من سجل الأوردرات',
                actions: [
                  AppSearchField(hint: 'بحث', onChanged: controller.search, width: 200),
                  SizedBox(
                    width: 200,
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
                  AppButton(
                    label: 'مزامنة الطلبات',
                    icon: AppIcons.refresh,
                    variant: AppButtonVariant.outlined,
                    isLoading: controller.isSyncingSold,
                    onPressed: () => controller.syncSoldCounts(),
                  ),
                ],
              ),
              if (controller.isSaving || controller.isSyncingSold) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(minHeight: 2),
              ],
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

  Widget _body(ProductOrderController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<ProductOrderController>(
      id: ProductOrderController.listId,
      builder: (controller) {
        final items = controller.filtered;
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: AppIcons.reorder,
            title: 'لا توجد منتجات',
            message: 'غيّر القسم أو البحث',
          );
        }
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: items.length,
          onReorder: controller.isSaving ? (_, __) {} : controller.onReorder,
          proxyDecorator: (child, index, animation) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          itemBuilder: (context, index) {
            final product = items[index];
            final c = context.colors;
            final sold = controller.soldCountOf(product);
            return ListTile(
              key: ValueKey(product.docId),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_indicator_rounded, color: c.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _OrderField(
                    product: product,
                    onSubmit: (value) => controller.setTypedOrder(product, value),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _thumb(product, c),
                ],
              ),
              title: Text(product.displayName, style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
              subtitle: Text(
                product.catAr.isNotEmpty ? product.catAr : product.cat,
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$sold',
                      style: AppTextStyles.body1.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                    ),
                    Text('طلب', style: AppTextStyles.caption.copyWith(color: c.textSecondary, fontSize: 10)),
                  ],
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
        width: 44,
        height: 44,
        child: url.isEmpty
            ? ColoredBox(color: c.border, child: Icon(AppIcons.products, color: c.textSecondary, size: AppIconSize.md))
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: c.border)),
      ),
    );
  }
}

class _OrderField extends StatefulWidget {
  final ProductModel product;
  final ValueChanged<String> onSubmit;

  const _OrderField({required this.product, required this.onSubmit});

  @override
  State<_OrderField> createState() => _OrderFieldState();
}

class _OrderFieldState extends State<_OrderField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.product.order?.toString() ?? '');
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _OrderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.order != widget.product.order && !_focus.hasFocus) {
      _controller.text = widget.product.order?.toString() ?? '';
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final next = _controller.text.trim();
    final current = widget.product.order?.toString() ?? '';
    if (next.isEmpty || next == current) return;
    widget.onSubmit(next);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: AppTextStyles.body2.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: '#',
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          filled: true,
          fillColor: c.surface,
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
            borderSide: BorderSide(color: c.primary),
          ),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}
