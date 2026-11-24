import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../media/controllers/image_editor_controller.dart';
import '../models/category_model.dart';
import '../repositories/categories_repository.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesController extends GetxController {
  static const String formId = 'category_form';

  final CategoriesRepository _repository = CategoriesRepository();
  StreamSubscription<List<CategoryModel>>? _subscription;

  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController orderController = TextEditingController();
  CategoryModel? editing;
  bool isSaving = false;
  bool isUploading = false;

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.watchCategories().listen(
      (data) {
        categories = data;
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
  }

  void openForm([CategoryModel? category]) {
    editing = category;
    nameController.text = category?.name ?? '';
    nameArController.text = category?.nameAr ?? '';
    imageController.text = category?.image ?? '';
    orderController.text = '${category?.order ?? categories.length + 1}';
    Get.dialog(const CategoryFormDialog());
  }

  /// Refreshes the image preview while the URL is typed.
  void onImageChanged() => update([formId]);

  Future<void> uploadImage() async {
    if (isUploading) return;
    isUploading = true;
    update([formId]);
    try {
      final uploaded = await ImageEditorController.pickEditUpload(kind: ImageKind.category);
      if (uploaded.isNotEmpty) imageController.text = uploaded.first.url;
    } catch (e) {
      AppSnackbar.show('تعذر رفع الصورة: $e', type: AppSnackbarType.error);
    } finally {
      isUploading = false;
      update([formId]);
    }
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final nameAr = nameArController.text.trim();
    if (name.isEmpty || nameAr.isEmpty) {
      AppSnackbar.show('اكتب اسم القسم بالعربي والإنجليزي', type: AppSnackbarType.error);
      return;
    }
    final duplicate = categories.any((c) => c.name.toLowerCase() == name.toLowerCase() && c.docId != editing?.docId);
    if (duplicate) {
      AppSnackbar.show('يوجد قسم بنفس الاسم', type: AppSnackbarType.error);
      return;
    }
    isSaving = true;
    update([formId]);
    try {
      await _repository.save(
        CategoryModel(
          docId: editing?.docId ?? '',
          name: name,
          nameAr: nameAr,
          image: imageController.text.trim(),
          order: int.tryParse(orderController.text.trim()),
        ),
        previous: editing,
      );
      Get.back();
      AppSnackbar.show(editing == null ? 'تمت إضافة القسم' : 'تم تحديث القسم');
    } catch (e) {
      AppSnackbar.show('تعذر حفظ القسم: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update([formId]);
    }
  }

  Future<void> delete(CategoryModel category) async {
    final count = await _repository.productCount(category.name);
    final confirmed = await AppConfirmDialog.show(
      title: 'حذف القسم',
      message: count > 0
          ? 'يحتوي هذا القسم على $count منتج. سيتم حذف القسم فقط وستبقى المنتجات بدون قسم ظاهر.'
          : 'هل تريد حذف قسم "${category.nameAr}"؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await _repository.delete(category.docId);
      AppSnackbar.show('تم حذف القسم');
    } catch (e) {
      AppSnackbar.show('تعذر حذف القسم: $e', type: AppSnackbarType.error);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    nameController.dispose();
    nameArController.dispose();
    imageController.dispose();
    orderController.dispose();
    super.onClose();
  }
}
