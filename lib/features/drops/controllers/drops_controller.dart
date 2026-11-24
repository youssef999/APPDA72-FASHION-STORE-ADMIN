import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../media/controllers/image_editor_controller.dart';
import '../../products/models/product_model.dart';
import '../../products/repositories/products_repository.dart';
import '../models/drop_model.dart';
import '../repositories/drops_repository.dart';
import '../widgets/drop_form_dialog.dart';

class DropsController extends GetxController {
  static const String listId = 'drops_list';
  static const String formId = 'drop_form';

  final DropsRepository _repository = DropsRepository();
  final ProductsRepository _productsRepository = ProductsRepository();
  StreamSubscription<List<DropModel>>? _subscription;

  List<DropModel> drops = [];
  List<ProductModel> products = [];
  bool isLoading = true;
  String? error;
  DropStatus? statusFilter;
  String query = '';

  final title = TextEditingController();
  final titleAr = TextEditingController();
  final subtitle = TextEditingController(text: 'App exclusive · 2h early');
  final subtitleAr = TextEditingController(text: 'حصري للتطبيق · قبل الموقع بساعتين');
  String coverImage = '';
  DateTime launchAt = DateTime.now().add(const Duration(days: 1));
  DateTime webUnlockAt = DateTime.now().add(const Duration(days: 1, hours: 2));
  DropStatus status = DropStatus.scheduled;
  final Set<String> selectedProductIds = {};
  DropModel? editing;
  bool isSaving = false;
  bool isUploadingCover = false;

  List<DropModel> get filtered =>
      drops.where((d) => (statusFilter == null || d.status == statusFilter) && d.matches(query)).toList();

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.watchDrops().listen(
      (data) {
        drops = data;
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
    _productsRepository.watchProducts().first.then((list) {
      products = list;
      update([formId]);
    }).catchError((_) {});
  }

  void setStatusFilter(DropStatus? status) {
    statusFilter = status;
    update();
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  Future<void> openForm({DropModel? drop}) async {
    editing = drop;
    title.text = drop?.title ?? '';
    titleAr.text = drop?.titleAr ?? '';
    subtitle.text = drop?.subtitle ?? 'App exclusive · 2h early';
    subtitleAr.text = drop?.subtitleAr ?? 'حصري للتطبيق · قبل الموقع بساعتين';
    coverImage = drop?.coverImage ?? '';
    launchAt = drop?.launchAt ?? DateTime.now().add(const Duration(days: 1));
    webUnlockAt = drop?.webUnlockAt ?? launchAt.add(const Duration(hours: 2));
    status = drop?.status ?? DropStatus.scheduled;
    selectedProductIds
      ..clear()
      ..addAll(drop?.productIds ?? const []);
    if (products.isEmpty) {
      try {
        products = await _productsRepository.watchProducts().first;
      } catch (_) {}
    }
    Get.dialog(const DropFormDialog(), barrierDismissible: false);
    update([formId]);
  }

  void setLaunchAt(DateTime value) {
    launchAt = value;
    webUnlockAt = value.add(const Duration(hours: 2));
    update([formId]);
  }

  void setWebUnlockAt(DateTime value) {
    webUnlockAt = value;
    update([formId]);
  }

  void setStatus(DropStatus? value) {
    if (value == null) return;
    status = value;
    update([formId]);
  }

  void toggleProduct(String productId) {
    if (selectedProductIds.contains(productId)) {
      selectedProductIds.remove(productId);
    } else {
      selectedProductIds.add(productId);
    }
    update([formId]);
  }

  Future<void> uploadCover() async {
    if (isUploadingCover) return;
    isUploadingCover = true;
    update([formId]);
    try {
      final uploaded = await ImageEditorController.pickEditUpload(kind: ImageKind.category);
      if (uploaded.isNotEmpty) coverImage = uploaded.first.url;
    } catch (e) {
      AppSnackbar.show('تعذر رفع الغلاف: $e', type: AppSnackbarType.error);
    } finally {
      isUploadingCover = false;
      update([formId]);
    }
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty || titleAr.text.trim().isEmpty) {
      AppSnackbar.show('اكتب عنوان الإطلاق بالعربي والإنجليزي', type: AppSnackbarType.error);
      return;
    }
    if (selectedProductIds.isEmpty) {
      AppSnackbar.show('اختر منتجاً واحداً على الأقل', type: AppSnackbarType.error);
      return;
    }
    if (!webUnlockAt.isAfter(launchAt)) {
      AppSnackbar.show('وقت فتح الموقع يجب أن يكون بعد الإطلاق', type: AppSnackbarType.error);
      return;
    }
    isSaving = true;
    update([formId]);
    try {
      await _repository.save(DropModel(
        id: editing?.id ?? '',
        title: title.text.trim(),
        titleAr: titleAr.text.trim(),
        subtitle: subtitle.text.trim(),
        subtitleAr: subtitleAr.text.trim(),
        coverImage: coverImage,
        launchAt: launchAt,
        webUnlockAt: webUnlockAt,
        productIds: selectedProductIds.toList(),
        status: status,
        pushSentAt: editing?.pushSentAt,
      ));
      Get.back<void>();
      AppSnackbar.show(editing == null ? 'تم إنشاء الإطلاق' : 'تم تحديث الإطلاق');
    } catch (e) {
      AppSnackbar.show('تعذر الحفظ: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update([formId]);
    }
  }

  Future<void> delete(DropModel drop) async {
    final ok = await AppConfirmDialog.show(
      title: 'حذف الإطلاق',
      message: 'سيتم حذف "${drop.displayTitle}" وإلغاء ربط منتجاته.',
      confirmLabel: 'حذف',
    );
    if (!ok) return;
    try {
      await _repository.delete(drop.id);
      AppSnackbar.show('تم حذف الإطلاق');
    } catch (e) {
      AppSnackbar.show('تعذر الحذف: $e', type: AppSnackbarType.error);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    for (final c in [title, titleAr, subtitle, subtitleAr]) {
      c.dispose();
    }
    super.onClose();
  }
}
