import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/drops_controller.dart';
import '../models/drop_model.dart';

class DropsPage extends StatelessWidget {
  const DropsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.drops,
      title: 'الإطلاقات',
      body: GetBuilder<DropsController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'إطلاقات حصرية للتطبيق',
                subtitle: 'عدّ تنازلي · تذكير Push · فتح قبل الموقع بساعتين',
                actions: [
                  AppSearchField(hint: 'بحث', onChanged: controller.search),
                  AppButton(label: 'إطلاق جديد', icon: AppIcons.add, onPressed: controller.openForm),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _Chip(label: 'الكل', selected: controller.statusFilter == null, onTap: () => controller.setStatusFilter(null)),
                  ...DropStatus.values.map(
                    (s) => _Chip(
                      label: DropModel.statusLabel(s),
                      selected: controller.statusFilter == s,
                      onTap: () => controller.setStatusFilter(s),
                    ),
                  ),
                ],
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

  Widget _body(DropsController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<DropsController>(
      id: DropsController.listId,
      builder: (controller) {
        final items = controller.filtered;
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: AppIcons.drops,
            title: 'لا توجد إطلاقات',
            message: 'أنشئ إطلاقاً مغلقاً ليظهر العدّ التنازلي في التطبيق',
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final drop = items[index];
            final c = context.colors;
            return ListTile(
              title: Text(drop.displayTitle, style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
              subtitle: Text(
                '${DropModel.statusLabel(drop.status)} · ${Formatters.dateTime(drop.launchAt)} · ${drop.productIds.length} منتج',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => controller.openForm(drop: drop), icon: Icon(AppIcons.edit, color: c.textSecondary)),
                  IconButton(onPressed: () => controller.delete(drop), icon: Icon(AppIcons.delete, color: c.error)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.primary,
      labelStyle: AppTextStyles.caption.copyWith(color: selected ? c.onPrimary : c.textPrimary),
    );
  }
}
