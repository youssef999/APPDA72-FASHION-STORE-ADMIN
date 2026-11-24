import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/routes/app_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/shell/controllers/shell_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  //admin@thehatch.com
  //Hatcha6c769!
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initializeDateFormatting('en');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  AppBinding().dependencies();
  // The route guards read `isAdmin` synchronously, so the session is restored before the first frame.
  await Get.find<AuthController>().restoreSession();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget
{
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShellController>(
      builder: (shell) => GetMaterialApp(
        title: 'APPDA 72 • Admin',
        debugShowCheckedModeBanner: false,
        textDirection: TextDirection.rtl,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: shell.themeMode,
        initialRoute: AppRoutes.dashboard,
        getPages: AppPages.pages,
        unknownRoute: AppPages.pages.first,
      ),
    );
  }
}
