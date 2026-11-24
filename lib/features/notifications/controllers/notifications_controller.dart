import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../models/notification_model.dart';
import '../repositories/notifications_repository.dart';

/// A single recipient chosen from the users page.
class NotificationRecipient {
  final String uid;
  final String email;
  final String name;

  const NotificationRecipient({required this.uid, required this.email, required this.name});
}

class NotificationsController extends GetxController {
  static const String formId = 'notification_form';

  final NotificationsRepository _repository = NotificationsRepository();
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> history = [];
  bool isLoading = true;
  String? error;

  final TextEditingController titleArController = TextEditingController();
  final TextEditingController bodyArController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  NotificationRecipient? recipient;
  bool isSending = false;

  @override
  void onInit() {
    super.onInit();
    final uid = Get.parameters['uid'] ?? '';
    final email = Get.parameters['email'] ?? '';
    if (uid.isNotEmpty || email.isNotEmpty) {
      recipient = NotificationRecipient(uid: uid, email: email, name: Get.parameters['name'] ?? email);
    }
    _subscription = _repository.watchLatest().listen(
      (data) {
        history = data;
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

  void clearRecipient() {
    recipient = null;
    update([formId]);
  }

  /// English fields are optional; the app falls back to the Arabic text.
  Future<void> send() async {
    final titleAr = titleArController.text.trim();
    final bodyAr = bodyArController.text.trim();
    if (titleAr.isEmpty || bodyAr.isEmpty) {
      AppSnackbar.show('اكتب عنوان ونص الإشعار بالعربي', type: AppSnackbarType.error);
      return;
    }
    final target = recipient;
    if (target == null) {
      final confirmed = await AppConfirmDialog.show(
        title: 'إرسال لكل المستخدمين',
        message: 'سيظهر هذا الإشعار لكل مستخدمي التطبيق. هل تريد المتابعة؟',
        confirmLabel: 'إرسال',
      );
      if (!confirmed) return;
    }
    isSending = true;
    update([formId]);
    try {
      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      await _repository.send(NotificationModel(
        title: title.isEmpty ? titleAr : title,
        titleAr: titleAr,
        body: body.isEmpty ? bodyAr : body,
        bodyAr: bodyAr,
        target: target == null || target.uid.isEmpty ? NotificationModel.targetAll : target.uid,
        targetEmail: target?.email ?? '',
        type: target == null ? 'broadcast' : 'personal',
      ));
      for (final field in [titleArController, bodyArController, titleController, bodyController]) {
        field.clear();
      }
      AppSnackbar.show(target == null ? 'تم إرسال الإشعار لكل المستخدمين' : 'تم إرسال الإشعار إلى ${target.name}');
    } catch (e) {
      AppSnackbar.show('تعذر إرسال الإشعار: $e', type: AppSnackbarType.error);
    } finally {
      isSending = false;
      update([formId]);
    }
  }

  Future<void> delete(NotificationModel notification) async {
    final confirmed = await AppConfirmDialog.show(
      title: 'حذف الإشعار',
      message: 'سيتم حذفه من السجل، ولن يظهر لمن لم يستلمه بعد.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      await _repository.delete(notification.id);
      AppSnackbar.show('تم حذف الإشعار');
    } catch (e) {
      AppSnackbar.show('تعذر حذف الإشعار: $e', type: AppSnackbarType.error);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    titleArController.dispose();
    bodyArController.dispose();
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }
}
