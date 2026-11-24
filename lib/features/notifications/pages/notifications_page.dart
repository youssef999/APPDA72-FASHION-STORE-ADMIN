import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../widgets/notification_composer.dart';
import '../widgets/notifications_history.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const _toolbar = PageToolbar(
    title: 'إشعارات العملاء',
    subtitle: 'تظهر الإشعارات في تطبيق المتجر عند فتحه أو أثناء تشغيله',
  );

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.notifications,
      title: 'الإشعارات',
      body: Breakpoints.isDesktop(context) ? _desktop() : _stacked(),
    );
  }

  Widget _desktop() => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar,
            SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: SingleChildScrollView(child: NotificationComposer())),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 3,
                    child: AppCard(title: 'السجل', expand: true, child: NotificationsHistory()),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _stacked() => const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar,
            SizedBox(height: AppSpacing.lg),
            NotificationComposer(),
            SizedBox(height: AppSpacing.lg),
            AppCard(title: 'السجل', child: NotificationsHistory(shrinkWrap: true)),
          ],
        ),
      );
}
