import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// App-wide UI preferences: theme mode and the collapsed state of the sidebar.
class ShellController extends GetxController {
  static const String _darkKey = 'admin_dark_mode';
  static const String _collapsedKey = 'admin_sidebar_collapsed';

  final GetStorage _storage = GetStorage();

  late bool isDark = _storage.read<bool>(_darkKey) ?? false;
  late bool sidebarCollapsed = _storage.read<bool>(_collapsedKey) ?? false;

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDark = !isDark;
    _storage.write(_darkKey, isDark);
    update();
  }

  void toggleSidebar() {
    sidebarCollapsed = !sidebarCollapsed;
    _storage.write(_collapsedKey, sidebarCollapsed);
    update(['sidebar']);
  }
}
