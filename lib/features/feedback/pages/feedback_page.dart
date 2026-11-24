import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/feedback_controller.dart';
import '../models/feedback_model.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.feedback,
      title: 'الشكاوي والمقترحات',
      body: GetBuilder<FeedbackController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'متابعة بلاغات العملاء',
                subtitle: 'شكاوي ومقترحات من التطبيق — حدّث الحالة وأضف ملاحظة متابعة',
                actions: [
                  AppSearchField(hint: 'بحث بالعنوان أو العميل', onChanged: controller.search),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Chip(label: 'الكل', selected: controller.statusFilter == null, onTap: () => controller.setStatusFilter(null)),
                  ...FeedbackStatus.all.map(
                    (s) => _Chip(
                      label: FeedbackStatus.label(s),
                      selected: controller.statusFilter == s,
                      onTap: () => controller.setStatusFilter(s),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _Chip(
                    label: 'شكاوي',
                    selected: controller.typeFilter == FeedbackType.complaint,
                    onTap: () => controller.setTypeFilter(
                      controller.typeFilter == FeedbackType.complaint ? null : FeedbackType.complaint,
                    ),
                  ),
                  _Chip(
                    label: 'مقترحات',
                    selected: controller.typeFilter == FeedbackType.suggestion,
                    onTap: () => controller.setTypeFilter(
                      controller.typeFilter == FeedbackType.suggestion ? null : FeedbackType.suggestion,
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

  Widget _body(FeedbackController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<FeedbackController>(
      id: FeedbackController.listId,
      builder: (controller) {
        final items = controller.filtered;
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: AppIcons.feedback,
            title: 'لا توجد بلاغات',
            message: 'ستظهر هنا الشكاوي والمقترحات المرسلة من التطبيق',
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final c = context.colors;
            return ListTile(
              onTap: () => controller.openDetails(item),
              leading: CircleAvatar(
                backgroundColor: item.type == FeedbackType.complaint
                    ? c.warning.withValues(alpha: 0.15)
                    : c.info.withValues(alpha: 0.15),
                child: Icon(
                  item.type == FeedbackType.complaint ? Icons.report_outlined : Icons.lightbulb_outline_rounded,
                  color: item.type == FeedbackType.complaint ? c.warning : c.info,
                  size: AppIconSize.md,
                ),
              ),
              title: Text(item.title, style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
              subtitle: Text(
                '${FeedbackType.label(item.type)} · ${FeedbackStatus.label(item.status)} · ${item.displayUser} · ${Formatters.dateTime(item.createdAt)}',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
              trailing: IconButton(
                onPressed: () => controller.confirmDelete(item),
                icon: Icon(AppIcons.delete, color: c.error),
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.primary.withValues(alpha: 0.12),
      checkmarkColor: c.primary,
    );
  }
}
