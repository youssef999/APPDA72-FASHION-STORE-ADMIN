import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';

class FeedbackController extends GetxController {
  static const String listId = 'feedback_list';
  static const String dialogId = 'feedback_dialog';

  final FeedbackRepository _repo = FeedbackRepository();
  StreamSubscription? _sub;

  List<FeedbackModel> items = [];
  bool isLoading = true;
  String? error;
  String query = '';
  String? statusFilter;
  String? typeFilter;

  List<FeedbackModel> get filtered => items.where((item) {
        if (statusFilter != null && item.status != statusFilter) return false;
        if (typeFilter != null && item.type != typeFilter) return false;
        return item.matches(query);
      }).toList();

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchAll().listen(
      (data) {
        items = data;
        isLoading = false;
        error = null;
        update();
        update([listId]);
      },
      onError: (e) {
        error = '$e';
        isLoading = false;
        update();
      },
    );
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  void setStatusFilter(String? value) {
    statusFilter = value;
    update();
    update([listId]);
  }

  void setTypeFilter(String? value) {
    typeFilter = value;
    update();
    update([listId]);
  }

  Future<void> openDetails(FeedbackModel item) async {
    final note = TextEditingController(text: item.adminNote);
    var status = item.status;

    await Get.dialog(
      GetBuilder<FeedbackController>(
        id: dialogId,
        builder: (_) {
          final c = Get.context!.colors;
          return AlertDialog(
            backgroundColor: c.card,
            title: Text(item.title, style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${FeedbackType.label(item.type)} · ${item.displayUser}',
                      style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                    ),
                    if (item.userEmail.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.userEmail, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(item.description, style: AppTextStyles.body1.copyWith(color: c.textPrimary, height: 1.5)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('الحالة', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: FeedbackStatus.all
                          .map(
                            (s) => ChoiceChip(
                              label: Text(FeedbackStatus.label(s)),
                              selected: status == s,
                              onSelected: (_) {
                                status = s;
                                update([dialogId]);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: note,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'ملاحظة المتابعة',
                        hintText: 'اختياري — رد داخلي أو ملاحظة للفريق',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('إغلاق')),
              AppButton(
                label: 'حفظ المتابعة',
                onPressed: () async {
                  try {
                    await _repo.updateStatus(id: item.id, status: status, adminNote: note.text.trim());
                    Get.back();
                    AppSnackbar.show('تم تحديث المتابعة');
                  } catch (e) {
                    AppSnackbar.show('تعذر التحديث: $e', type: AppSnackbarType.error);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
    note.dispose();
  }

  Future<void> confirmDelete(FeedbackModel item) async {
    final ok = await AppConfirmDialog.show(
      title: 'حذف البلاغ؟',
      message: 'سيتم حذف "${item.title}" نهائياً.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!ok) return;
    try {
      await _repo.delete(item.id);
      AppSnackbar.show('تم الحذف');
    } catch (e) {
      AppSnackbar.show('تعذر الحذف: $e', type: AppSnackbarType.error);
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
