import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository = AuthRepository();

  /// Demo admin — Auth + `admins/admin@test.com` provisioned for easy local login.
  final TextEditingController emailController = TextEditingController(text: 'admin@test.com');
  final TextEditingController passwordController = TextEditingController(text: '123456');

  bool isAdmin = false;
  bool isLoading = false;
  String? errorMessage;

  String get adminEmail => _repository.currentUser?.email ?? '';

  Future<void> restoreSession() async {
    final user = await _repository.restoreSession();
    if (user == null) return;
    try {
      isAdmin = await _repository.isAdmin(user);
    } catch (_) {
      isAdmin = false;
    }
    if (!isAdmin) await _repository.signOut();
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _setError('اكتب البريد الإلكتروني وكلمة المرور');
      return;
    }
    isLoading = true;
    errorMessage = null;
    update();
    try {
      final user = await _repository.signIn(email, password);
      isAdmin = await _repository.isAdmin(user);
      if (!isAdmin) {
        await _repository.signOut();
        _setError('هذا الحساب ليس لديه صلاحية دخول لوحة التحكم');
        return;
      }
      passwordController.clear();
      isLoading = false;
      update();
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      _setError(_authMessage(e.code));
    } catch (e) {
      _setError('حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    isAdmin = false;
    update();
    Get.offAllNamed(AppRoutes.login);
    AppSnackbar.show('تم تسجيل الخروج', type: AppSnackbarType.info);
  }

  void _setError(String message) {
    isLoading = false;
    errorMessage = message;
    update();
  }

  String _authMessage(String code) => switch (code) {
        'invalid-email' => 'البريد الإلكتروني غير صالح',
        'user-disabled' => 'هذا الحساب موقوف',
        'too-many-requests' => 'محاولات كثيرة، حاول لاحقاً',
        'network-request-failed' => 'تحقق من الاتصال بالإنترنت',
        _ => 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      };

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
