import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/branding/controllers/branding_controller.dart';

/// Returns up to 2-character initials from a brand name, e.g. "APPDA 72" → "A7".
String _brandInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '';
  if (words.length == 1) {
    return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
  }
  return words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
}

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem(this.label, this.icon, this.route);
}

class SidebarGroup {
  final String title;
  final List<SidebarItem> items;

  const SidebarGroup(this.title, this.items);
}

/// Merchant-friendly groups — fewer cognitive hops than a flat 15-item list.
const List<SidebarGroup> sidebarGroups = [
  SidebarGroup('نظرة عامة', [
    SidebarItem('الرئيسية', AppIcons.dashboard, AppRoutes.dashboard),
    SidebarItem('التحليلات', AppIcons.analytics, AppRoutes.analytics),
    SidebarItem('الطلبات', AppIcons.orders, AppRoutes.orders),
  ]),
  SidebarGroup('الكتالوج', [
    SidebarItem('المنتجات', AppIcons.products, AppRoutes.products),
    SidebarItem('الأقسام', AppIcons.categories, AppRoutes.categories),
    SidebarItem('الأفضل مبيعاً', AppIcons.bestSeller, AppRoutes.bestSellers),
    SidebarItem('ترتيب العرض', AppIcons.reorder, AppRoutes.productOrder),
  ]),
  SidebarGroup('التسويق', [
    SidebarItem('الكوبونات', AppIcons.coupon, AppRoutes.coupons),
    SidebarItem('الإطلاقات', AppIcons.drops, AppRoutes.drops),
    SidebarItem('الإشعارات', AppIcons.notifications, AppRoutes.notifications),
    SidebarItem('الموسم', AppIcons.seasonal, AppRoutes.seasonal),
  ]),
  SidebarGroup('الإعدادات', [
    SidebarItem('إعدادات المتجر', AppIcons.settings, AppRoutes.storeSettings),
    SidebarItem('الهوية البصرية', AppIcons.branding, AppRoutes.branding),
    SidebarItem('المدفوعات', AppIcons.revenue, AppRoutes.payments),
    SidebarItem('المستخدمون', AppIcons.users, AppRoutes.users),
    SidebarItem('الشكاوي', AppIcons.feedback, AppRoutes.feedback),
  ]),
];

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final bool collapsed;

  const Sidebar({super.key, required this.currentRoute, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? 84 : 248,
      color: c.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GetBuilder<BrandingController>(
              builder: (branding) {
                final name = branding.draft.brandName;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        collapsed ? _brandInitials(name) : name,
                        style: AppTextStyles.h4.copyWith(color: c.onSidebar, letterSpacing: 4),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!collapsed)
                        Text(
                          'لوحة التاجر',
                          style: AppTextStyles.overline.copyWith(color: AppColors.light.secondary),
                        ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
                children: [
                  for (final group in sidebarGroups) ...[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          group.title,
                          style: AppTextStyles.caption.copyWith(
                            color: c.onSidebar.withValues(alpha: 0.45),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    for (final item in group.items)
                      _SidebarTile(
                        item: item,
                        collapsed: collapsed,
                        selected: _isSelected(item.route),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String route) {
    if (route == AppRoutes.dashboard) return currentRoute == route;
    return currentRoute.startsWith(route);
  }
}

class _SidebarTile extends StatelessWidget {
  final SidebarItem item;
  final bool collapsed;
  final bool selected;

  const _SidebarTile({required this.item, required this.collapsed, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gold = AppColors.light.secondary;
    final Color foreground = selected ? gold : c.onSidebar.withValues(alpha: 0.72);
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected ? gold.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.of(context).pop();
            if (!selected) Get.offAllNamed(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(item.icon, size: AppIconSize.md, color: foreground),
                if (!collapsed) ...[
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(child: Text(item.label, style: AppTextStyles.h6.copyWith(color: foreground))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: item.label, child: tile) : tile;
  }
}
