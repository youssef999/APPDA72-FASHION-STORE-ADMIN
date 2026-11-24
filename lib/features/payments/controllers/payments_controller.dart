import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../models/payment_config_model.dart';
import '../repositories/payments_repository.dart';

class PaymentsController extends GetxController {
  final PaymentsRepository _repo = PaymentsRepository();

  PaymentConfigModel config = const PaymentConfigModel();
  PaymentSecretsModel secrets = const PaymentSecretsModel();
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  static const methodOptions = ['MADA', 'APPLE_PAY', 'VISA', 'MASTERCARD', 'STC_PAY', 'GOOGLE_PAY'];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    update();
    try {
      config = await _repo.fetchConfig();
      secrets = await _repo.fetchSecrets();
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
      update();
    }
  }

  void patchConfig(PaymentConfigModel next) {
    config = next;
    update();
  }

  void patchSecrets(PaymentSecretsModel next) {
    secrets = next;
    update();
  }

  void toggleMethod(String method) {
    final list = [...config.supportedMethods];
    if (list.contains(method)) {
      list.remove(method);
    } else {
      list.add(method);
    }
    config = config.copyWith(supportedMethods: list);
    update();
  }

  Future<void> save() async {
    if (isSaving) return;
    isSaving = true;
    update();
    try {
      await _repo.saveConfig(config);
      await _repo.saveSecrets(secrets);
      AppSnackbar.show('تم حفظ إعدادات المدفوعات بنجاح', type: AppSnackbarType.success);
    } catch (e) {
      AppSnackbar.show('فشل الحفظ: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update();
    }
  }
}
