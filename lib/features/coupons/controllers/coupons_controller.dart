import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../users/models/user_model.dart';
import '../../users/repositories/users_repository.dart';
import '../models/coupon_model.dart';
import '../repositories/coupons_repository.dart';
import '../widgets/coupon_form_dialog.dart';
import '../widgets/influencer_report_dialog.dart';

/// The single customer a personal coupon is issued to.
class CouponRecipient {
  final String uid;
  final String email;
  final String name;

  const CouponRecipient({required this.uid, required this.email, required this.name});
}

class CouponsController extends GetxController {
  static const String listId = 'coupons_list';
  static const String formId = 'coupon_form';
  static const int _codeLength = 8;

  final CouponsRepository _repository = CouponsRepository();
  final UsersRepository _usersRepository = UsersRepository();
  StreamSubscription<List<CouponModel>>? _subscription;

  List<CouponModel> coupons = [];
  bool isLoading = true;
  String? error;
  CouponStatus? statusFilter;
  String query = '';

  final TextEditingController codeController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController influencerNameController = TextEditingController();
  final TextEditingController influencerNameArController = TextEditingController();
  String type = CouponModel.percent;
  DateTime? expiresAt;
  CouponRecipient? recipient;
  List<UserModel> users = [];
  bool isSaving = false;
  bool isInfluencerCampaign = false;
  int attributionWindowDays = 7;

  List<CouponModel> get filtered =>
      coupons.where((c) => (statusFilter == null || c.status == statusFilter) && c.matches(query)).toList();

  int countFor(CouponStatus? status) =>
      status == null ? coupons.length : coupons.where((c) => c.status == status).length;

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.watchCoupons().listen(
      (data) {
        coupons = data;
        isLoading = false;
        error = null;
        update();
      },
      onError: (Object e) {
        isLoading = false;
        error = '$e';
        update();
      },
    );
    final uid = Get.parameters['uid'] ?? '';
    if (uid.isNotEmpty) {
      final preset = CouponRecipient(
        uid: uid,
        email: Get.parameters['email'] ?? '',
        name: Get.parameters['name'] ?? '',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => openForm(recipient: preset));
    }
  }

  void setStatusFilter(CouponStatus? status) {
    statusFilter = status;
    update();
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  Future<void> openForm({CouponRecipient? recipient}) async {
    codeController.text = _randomCode();
    valueController.text = '10';
    type = CouponModel.percent;
    expiresAt = DateTime.now().add(const Duration(days: 7));
    this.recipient = recipient;
    isInfluencerCampaign = false;
    attributionWindowDays = 7;
    influencerNameController.clear();
    influencerNameArController.clear();
    Get.dialog(const CouponFormDialog());
    try {
      users = await _usersRepository.watchUsers().first;
      update([formId]);
    } catch (_) {
      // The recipient list stays empty; public coupons still work.
    }
  }

  void setInfluencerCampaign(bool value) {
    isInfluencerCampaign = value;
    update([formId]);
  }

  void setAttributionWindowDays(int days) {
    attributionWindowDays = days.clamp(1, 90);
    update([formId]);
  }

  void generateCode() {
    codeController.text = _randomCode();
    update([formId]);
  }

  void setType(String value) {
    type = value;
    update([formId]);
  }

  void setExpiry(DateTime day) {
    expiresAt = DateTime(day.year, day.month, day.day, 23, 59, 59);
    update([formId]);
  }

  /// `null` sends the coupon to everyone.
  void setRecipient(String? uid) {
    if (uid != null && uid == recipient?.uid) return;
    final user = users.firstWhereOrNull((u) => u.uid == uid);
    recipient = user == null ? null : CouponRecipient(uid: user.uid, email: user.email, name: user.displayName);
    update([formId]);
  }

  Future<void> save() async {
    final code = codeController.text.trim().toUpperCase();
    final value = Formatters.toNum(valueController.text);
    final error = _validate(code, value);
    if (error != null) {
      AppSnackbar.show(error, type: AppSnackbarType.error);
      return;
    }
    isSaving = true;
    update([formId]);
    try {
      final target = recipient;
      await _repository.create(CouponModel(
        code: code,
        type: type,
        value: value,
        expiresAt: expiresAt!,
        target: target?.uid ?? CouponModel.targetAll,
        targetEmail: target?.email ?? '',
        targetName: target?.name ?? '',
        campaignType: isInfluencerCampaign ? CouponModel.campaignInfluencer : '',
        influencerName: influencerNameController.text.trim(),
        influencerNameAr: influencerNameArController.text.trim(),
        attributionWindowDays: attributionWindowDays,
      ));
      Get.back();
      AppSnackbar.show(target == null ? 'تم إنشاء الكوبون وإشعار كل المستخدمين' : 'تم إهداء الكوبون إلى ${target.name}');
    } catch (e) {
      AppSnackbar.show('تعذر إنشاء الكوبون: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update([formId]);
    }
  }

  Future<void> openInfluencerReport(CouponModel coupon) async {
    Get.dialog(InfluencerReportDialog(coupon: coupon), barrierDismissible: false);
  }

  Future<void> toggleActive(CouponModel coupon) async {
    try {
      await _repository.setActive(coupon.code, !coupon.active);
      AppSnackbar.show(coupon.active ? 'تم إيقاف الكوبون' : 'تم تفعيل الكوبون');
    } catch (e) {
      AppSnackbar.show('تعذر تحديث الكوبون: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> delete(CouponModel coupon) async {
    final confirmed = await AppConfirmDialog.show(
      title: 'حذف الكوبون',
      message: 'سيتم حذف الكوبون ${coupon.code} ولن يمكن استخدامه. الطلبات السابقة لن تتأثر.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await _repository.delete(coupon.code);
      AppSnackbar.show('تم حذف الكوبون');
    } catch (e) {
      AppSnackbar.show('تعذر حذف الكوبون: $e', type: AppSnackbarType.error);
    }
  }

  String? _validate(String code, num value) {
    if (!RegExp(r'^[A-Z0-9_-]{4,20}$').hasMatch(code)) {
      return 'الكود من 4 إلى 20 حرف إنجليزي أو رقم، بدون مسافات';
    }
    if (value <= 0) return 'قيمة الخصم يجب أن تكون أكبر من صفر';
    if (type == CouponModel.percent && value > 100) return 'نسبة الخصم من 1 إلى 100';
    if (expiresAt == null || !expiresAt!.isAfter(DateTime.now())) return 'اختر تاريخ انتهاء في المستقبل';
    if (isInfluencerCampaign &&
        influencerNameController.text.trim().isEmpty &&
        influencerNameArController.text.trim().isEmpty) {
      return 'اكتب اسم المشهورة للحملة';
    }
    return null;
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(_codeLength, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    codeController.dispose();
    valueController.dispose();
    influencerNameController.dispose();
    influencerNameArController.dispose();
    super.onClose();
  }
}
