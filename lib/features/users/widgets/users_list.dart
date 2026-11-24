import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../controllers/users_controller.dart';
import '../models/user_model.dart';

/// Table rows on tablet/desktop, stacked cards on mobile.
class UsersList extends StatelessWidget {
  final List<UserModel> users;

  const UsersList({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return ListView.separated(
      itemCount: users.length + (isMobile ? 0 : 1),
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? AppSpacing.sm + 4 : 0),
      itemBuilder: (context, index) {
        if (!isMobile && index == 0) return const _HeaderRow();
        final user = users[isMobile ? index : index - 1];
        return isMobile ? _UserCard(user: user) : _UserRow(user: user);
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: context.colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('المستخدم', style: style)),
          Expanded(flex: 2, child: Text('طريقة الدخول', style: style)),
          Expanded(flex: 2, child: Text('الطلبات', style: style)),
          Expanded(flex: 2, child: Text('المشتريات', style: style)),
          Expanded(flex: 3, child: Text('آخر دخول', style: style)),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<UsersController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
      child: Row(
        children: [
          Expanded(flex: 4, child: _UserIdentity(user: user)),
          Expanded(flex: 2, child: _ProviderLabel(user: user)),
          Expanded(
            flex: 2,
            child: Text('${controller.ordersOf(user)}', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.money(controller.spentBy(user)), style: AppTextStyles.h6.copyWith(color: c.secondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(Formatters.dateTime(user.lastLoginAt), style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
          ),
          AppIconButton(icon: AppIcons.send, tooltip: 'إرسال إشعار', onPressed: () => controller.notify(user)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<UsersController>();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _UserIdentity(user: user)),
              AppIconButton(icon: AppIcons.send, tooltip: 'إرسال إشعار', onPressed: () => controller.notify(user)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              _ProviderLabel(user: user),
              const Spacer(),
              Text('${controller.ordersOf(user)} طلب • ', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
              Text(Formatters.money(controller.spentBy(user)), style: AppTextStyles.h6.copyWith(color: c.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserIdentity extends StatelessWidget {
  final UserModel user;

  const _UserIdentity({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        if (user.photoUrl.startsWith('http'))
          AppNetworkImage(url: user.photoUrl, width: 40, height: 40, radius: AppRadius.full)
        else
          CircleAvatar(
            radius: 20,
            backgroundColor: c.secondary.withValues(alpha: 0.14),
            child: Text(
              user.displayName.characters.first.toUpperCase(),
              style: AppTextStyles.h6.copyWith(color: c.secondary),
            ),
          ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(user.displayName,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: user.hasDeviceToken ? 'الإشعارات مفعّلة على جهازه' : 'لم يسجّل جهاز لاستقبال الإشعارات',
                    child: Icon(
                      AppIcons.notifications,
                      size: AppIconSize.sm,
                      color: user.hasDeviceToken ? c.success : c.textDisabled,
                    ),
                  ),
                ],
              ),
              Text(user.email.isEmpty ? '—' : user.email,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderLabel extends StatelessWidget {
  final UserModel user;

  const _ProviderLabel({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final platform = switch (user.platform) {
      'ios' => 'iOS',
      'android' => 'Android',
      _ => '',
    };
    return Text(
      platform.isEmpty ? user.providerLabel : '${user.providerLabel} • $platform',
      style: AppTextStyles.body2.copyWith(color: c.textSecondary),
    );
  }
}
