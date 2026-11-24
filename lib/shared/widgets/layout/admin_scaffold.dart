import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/shell/controllers/shell_controller.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Page frame: fixed sidebar on tablet/desktop, drawer on mobile.
class AdminScaffold extends StatelessWidget {
  final String route;
  final String title;
  final Widget body;
  final Widget? floatingAction;

  const AdminScaffold({
    super.key,
    required this.route,
    required this.title,
    required this.body,
    this.floatingAction,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      drawer: isMobile ? Drawer(child: Sidebar(currentRoute: route)) : null,
      floatingActionButton: floatingAction,
      body: Row(
        children: [
          if (!isMobile)
            GetBuilder<ShellController>(
              id: 'sidebar',
              builder: (shell) => Sidebar(
                currentRoute: route,
                collapsed: shell.sidebarCollapsed || !Breakpoints.isDesktop(context),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (context) => TopBar(
                    title: title,
                    onMenu: isMobile
                        ? () => Scaffold.of(context).openDrawer()
                        : Get.find<ShellController>().toggleSidebar,
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
