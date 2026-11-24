import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SeasonalAdminController extends GetxController {
  static const _doc = 'seasonal';

  String active = 'none';
  String bannerTitleAr = '';
  String bannerTitleEn = '';
  bool isLoading = true;
  bool isSaving = false;
  String? error;
  String? success;

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
      final snap = await FirebaseFirestore.instance.collection('config').doc(_doc).get();
      final data = snap.data() ?? {};
      active = '${data['active'] ?? 'none'}';
      bannerTitleAr = '${data['bannerTitleAr'] ?? ''}';
      bannerTitleEn = '${data['bannerTitleEn'] ?? ''}';
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> activate(String key) async {
    if (isSaving) return;
    isSaving = true;
    success = null;
    error = null;
    update();
    try {
      active = key;
      await FirebaseFirestore.instance.collection('config').doc(_doc).set({
        'active': key,
        'bannerTitleAr': bannerTitleAr,
        'bannerTitleEn': bannerTitleEn,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      success = key == 'none' ? 'تم إيقاف الموسم' : 'تم تفعيل الموسم فوراً في التطبيق';
    } catch (e) {
      error = '$e';
    } finally {
      isSaving = false;
      update();
    }
  }

  void setBannerAr(String v) {
    bannerTitleAr = v;
  }

  void setBannerEn(String v) {
    bannerTitleEn = v;
  }

  Future<void> saveTitles() async {
    await activate(active);
  }
}
