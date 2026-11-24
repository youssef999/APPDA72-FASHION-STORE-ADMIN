import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../repositories/store_app_config_repository.dart';

/// Edits `config/app.whatsappPhone` — single source for mobile WhatsApp express.
class StoreContactController extends GetxController {
  static const String formId = 'store_contact_form';

  final StoreAppConfigRepository _repo = StoreAppConfigRepository();
  final phoneCtrl = TextEditingController();

  StreamSubscription? _sub;
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watch().listen(
      (data) {
        final phone = '${data['whatsappPhone'] ?? ''}'.trim();
        if (phoneCtrl.text.trim() != phone) {
          phoneCtrl.text = phone;
        }
        isLoading = false;
        error = null;
        update([formId]);
        update();
      },
      onError: (e) {
        error = '$e';
        isLoading = false;
        update([formId]);
        update();
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    phoneCtrl.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (isSaving) return;
    final raw = phoneCtrl.text.trim();
    // Allow empty (disables WhatsApp in app) or E.164-ish digits.
    final normalized = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (normalized.isNotEmpty && !RegExp(r'^\+?\d{8,15}$').hasMatch(normalized)) {
      AppSnackbar.show(
        'أدخل رقمًا دوليًا صالحًا مثل +9665xxxxxxx أو اتركه فارغًا',
        type: AppSnackbarType.error,
      );
      return;
    }
    isSaving = true;
    update([formId]);
    update();
    try {
      await _repo.saveWhatsAppPhone(normalized);
      AppSnackbar.show('تم حفظ رقم الواتساب — يظهر فورًا في التطبيق');
    } catch (e) {
      AppSnackbar.show('تعذر الحفظ: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update([formId]);
      update();
    }
  }
}
