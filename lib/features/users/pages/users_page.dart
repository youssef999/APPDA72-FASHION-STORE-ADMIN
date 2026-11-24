import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_search_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/users_controller.dart';
import '../widgets/users_list.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.users,
      title: 'المستخدمون',
      body: GetBuilder<UsersController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageToolbar(
                title: 'عملاء المتجر',
                subtitle: '${controller.users.length} مستخدم • ${controller.withDeviceToken} منهم يستقبلون الإشعارات',
                actions: [AppSearchField(hint: 'الاسم أو البريد الإلكتروني', onChanged: controller.search)],
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

  Widget _body(UsersController controller) {
    if (controller.isLoading) return const AppLoader();
    if (controller.error != null) return AppErrorState(message: controller.error!);
    return GetBuilder<UsersController>(
      id: UsersController.listId,
      builder: (controller) {
        final users = controller.filtered;
        if (users.isEmpty) {
          return const AppEmptyState(icon: AppIcons.users, title: 'لا يوجد مستخدمون', message: 'لا يوجد مستخدم مطابق للبحث');
        }
        return UsersList(users: users);
      },
    );
  }
}
