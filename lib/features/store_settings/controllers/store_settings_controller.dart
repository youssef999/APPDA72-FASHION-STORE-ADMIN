import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../repositories/store_settings_repository.dart';

class StoreSettingsController extends GetxController {
  final StoreSettingsRepository _repo = StoreSettingsRepository();

  final freeShippingCtrl = TextEditingController();
  final vipGiftCtrl = TextEditingController();
  final vipOrdersCtrl = TextEditingController();
  final deliveryFeeCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? error;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    freeShippingCtrl.dispose();
    vipGiftCtrl.dispose();
    vipOrdersCtrl.dispose();
    deliveryFeeCtrl.dispose();
    whatsappCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    update();
    try {
      final snap = await _repo.fetch();
      freeShippingCtrl.text = _numText(snap.commerce['freeShippingMin'], 300);
      vipGiftCtrl.text = _numText(snap.commerce['vipGiftMin'], 420);
      vipOrdersCtrl.text = _numText(snap.commerce['vipOrdersRequired'], 2, asInt: true);
      deliveryFeeCtrl.text = _numText(snap.delivery['del'], 25);
      whatsappCtrl.text = '${snap.app['whatsappPhone'] ?? ''}'.trim();
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> save() async {
    if (isSaving) return;
    final freeMin = double.tryParse(freeShippingCtrl.text.trim());
    final vipGift = double.tryParse(vipGiftCtrl.text.trim());
    final vipOrders = int.tryParse(vipOrdersCtrl.text.trim());
    final delivery = double.tryParse(deliveryFeeCtrl.text.trim());
    final phone = whatsappCtrl.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');

    if (freeMin == null || freeMin < 0 || vipGift == null || vipGift < 0 || delivery == null || delivery < 0) {
      AppSnackbar.show('أدخل أرقامًا صحيحة للمبالغ (بالريال)', type: AppSnackbarType.error);
      return;
    }
    if (vipOrders == null || vipOrders < 1) {
      AppSnackbar.show('عدد طلبات VIP يجب أن يكون 1 أو أكثر', type: AppSnackbarType.error);
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
      AppSnackbar.show('رقم الواتساب غير صالح — مثال: +9665xxxxxxx', type: AppSnackbarType.error);
      return;
    }

    isSaving = true;
    update();
    try {
      await _repo.save(
        freeShippingMin: freeMin,
        vipGiftMin: vipGift,
        vipOrdersRequired: vipOrders,
        deliveryFee: delivery,
        whatsappPhone: phone,
      );
      AppSnackbar.show('تم حفظ إعدادات المتجر — تظهر في التطبيق فورًا');
    } catch (e) {
      AppSnackbar.show('تعذر الحفظ: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update();
    }
  }

  String _numText(dynamic raw, num fallback, {bool asInt = false}) {
    final n = raw is num ? raw : num.tryParse('${raw ?? ''}') ?? fallback;
    return asInt ? '${n.toInt()}' : (n % 1 == 0 ? '${n.toInt()}' : '$n');
  }
}
