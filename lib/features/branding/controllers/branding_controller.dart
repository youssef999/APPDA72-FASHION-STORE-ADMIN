import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/color_parser.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/branding_model.dart';
import '../models/branding_presets.dart';
import '../repositories/branding_repository.dart';

class BrandingController extends GetxController {
  static const String formId = 'branding_form';
  static const String previewId = 'branding_preview';

  final BrandingRepository _repo = BrandingRepository();
  StreamSubscription? _sub;

  final brandNameCtrl = TextEditingController();
  final primaryCtrl = TextEditingController();
  final accentCtrl = TextEditingController();
  final backgroundCtrl = TextEditingController();
  final buttonCtrl = TextEditingController();
  final buttonTextCtrl = TextEditingController();
  final iconCtrl = TextEditingController();
  final bannerTextCtrl = TextEditingController();

  BrandingModel draft = BrandingModel.defaults();
  String? activePresetId;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingLogo = false;
  String? error;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watch().listen(
      (model) {
        _hydrate(model);
        isLoading = false;
        error = null;
        update();
        update([formId, previewId]);
      },
      onError: (e) {
        error = '$e';
        isLoading = false;
        update();
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    brandNameCtrl.dispose();
    primaryCtrl.dispose();
    accentCtrl.dispose();
    backgroundCtrl.dispose();
    buttonCtrl.dispose();
    buttonTextCtrl.dispose();
    iconCtrl.dispose();
    bannerTextCtrl.dispose();
    super.onClose();
  }

  void _hydrate(BrandingModel model) {
    draft = model;
    brandNameCtrl.text = model.brandName;
    primaryCtrl.text = model.primaryHex;
    accentCtrl.text = model.accentHex;
    backgroundCtrl.text = model.backgroundHex;
    buttonCtrl.text = model.buttonHex;
    buttonTextCtrl.text = model.buttonTextHex;
    iconCtrl.text = model.iconHex;
    bannerTextCtrl.text = model.bannerTextHex;
    activePresetId = _matchPresetId(model);
  }

  String? _matchPresetId(BrandingModel model) {
    for (final preset in BrandingStylePreset.fashion) {
      final s = preset.style;
      if (s.primaryHex == model.primaryHex &&
          s.accentHex == model.accentHex &&
          s.backgroundHex == model.backgroundHex &&
          s.buttonHex == model.buttonHex &&
          s.bodyFont == model.bodyFont &&
          s.displayFont == model.displayFont) {
        return preset.id;
      }
    }
    return null;
  }

  void setBrandName(String value) {
    draft = draft.copyWith(brandName: value.trim().isEmpty ? BrandingModel.defaultBrandName : value.trim());
    update([previewId]);
  }

  void setBodyFont(String? key) {
    if (key == null) return;
    draft = draft.copyWith(bodyFont: key);
    update([formId, previewId]);
  }

  void setDisplayFont(String? key) {
    if (key == null) return;
    draft = draft.copyWith(displayFont: key);
    update([formId, previewId]);
  }

  void setPrimaryHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(primaryHex: hex);
          primaryCtrl.text = hex;
        },
      );

  void setAccentHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(accentHex: hex);
          accentCtrl.text = hex;
        },
      );

  void setBackgroundHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(backgroundHex: hex);
          backgroundCtrl.text = hex;
        },
      );

  void setButtonHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(buttonHex: hex);
          buttonCtrl.text = hex;
        },
      );

  void setButtonTextHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(buttonTextHex: hex);
          buttonTextCtrl.text = hex;
        },
      );

  void setIconHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(iconHex: hex);
          iconCtrl.text = hex;
        },
      );

  void setBannerTextHex(String value) => _setColor(
        value,
        apply: (hex) {
          draft = draft.copyWith(bannerTextHex: hex);
          bannerTextCtrl.text = hex;
        },
      );

  void _setColor(String value, {required void Function(String hex) apply}) {
    final hex = _validHexOrNull(value);
    if (hex == null) return;
    apply(hex);
    update([formId, previewId]);
  }

  Future<void> pickPrimarySwatch() async {
    final picked = await _pickColor(draft.primaryColor);
    if (picked != null) setPrimaryHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickAccentSwatch() async {
    final picked = await _pickColor(draft.accentColor);
    if (picked != null) setAccentHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickBackgroundSwatch() async {
    final picked = await _pickColor(draft.backgroundColor);
    if (picked != null) setBackgroundHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickButtonSwatch() async {
    final picked = await _pickColor(draft.buttonColor);
    if (picked != null) setButtonHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickButtonTextSwatch() async {
    final picked = await _pickColor(draft.buttonTextColor);
    if (picked != null) setButtonTextHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickIconSwatch() async {
    final picked = await _pickColor(draft.iconColor);
    if (picked != null) setIconHex(BrandingModel.colorToHex(picked));
  }

  Future<void> pickBannerTextSwatch() async {
    final picked = await _pickColor(draft.bannerTextColor);
    if (picked != null) setBannerTextHex(BrandingModel.colorToHex(picked));
  }

  Future<Color?> _pickColor(Color current) async {
    return Get.dialog<Color>(
      AlertDialog(
        title: const Text('اختر اللون'),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _palette)
                InkWell(
                  onTap: () => Get.back(result: color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == current ? Colors.black : Colors.black26,
                        width: color == current ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ],
      ),
    );
  }

  static const List<Color> _palette = [
    Color(0xFF1C1B1F),
    Color(0xFFB08D57),
    Color(0xFFFAF7F2),
    Color(0xFFFFFFFF),
    Color(0xFF0E0E10),
    Color(0xFFD4B483),
    Color(0xFF173B2B),
    Color(0xFF8C6A3F),
    Color(0xFFB4233C),
    Color(0xFF2A241D),
    Color(0xFFE8E1D7),
    Color(0xFF3B3229),
    Color(0xFF147B6C),
    Color(0xFFA143B5),
    Color(0xFF0277BD),
    Color(0xFF512DA8),
    Color(0xFF121212),
  ];

  Future<void> uploadLogo() async {
    try {
      isUploadingLogo = true;
      update([formId]);

      // Ensure the Firebase Auth session is alive before Storage write.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !Get.find<AuthController>().isAdmin) {
        AppSnackbar.show('جلسة الأدمن غير نشطة — سجّل الدخول مرة أخرى', type: AppSnackbarType.error);
        return;
      }
      await user.getIdToken(true);

      final picked = await ImageUploadService.pick();
      if (picked.isEmpty) return;
      final uploaded = await ImageUploadService.uploadBrandingLogo(picked.first.bytes);
      final previous = draft.logoUrl;
      draft = draft.copyWith(logoUrl: uploaded.url);
      if (previous.isNotEmpty && previous != uploaded.url) {
        try {
          await ImageUploadService.delete(previous);
        } catch (_) {}
      }
      update([formId, previewId]);
      AppSnackbar.show('تم رفع الشعار');
    } catch (e) {
      AppSnackbar.show('تعذر رفع الشعار: $e', type: AppSnackbarType.error);
    } finally {
      isUploadingLogo = false;
      update([formId]);
    }
  }

  Future<void> removeLogo() async {
    final previous = draft.logoUrl;
    draft = draft.copyWith(logoUrl: '');
    update([formId, previewId]);
    if (previous.isNotEmpty) {
      try {
        await ImageUploadService.delete(previous);
      } catch (_) {}
    }
  }

  Future<void> save() async {
    draft = draft.copyWith(
      brandName: brandNameCtrl.text.trim().isEmpty ? BrandingModel.defaultBrandName : brandNameCtrl.text.trim(),
      primaryHex: _validHexOrNull(primaryCtrl.text) ?? draft.primaryHex,
      accentHex: _validHexOrNull(accentCtrl.text) ?? draft.accentHex,
      backgroundHex: _validHexOrNull(backgroundCtrl.text) ?? draft.backgroundHex,
      buttonHex: _validHexOrNull(buttonCtrl.text) ?? draft.buttonHex,
      buttonTextHex: _validHexOrNull(buttonTextCtrl.text) ?? draft.buttonTextHex,
      iconHex: _validHexOrNull(iconCtrl.text) ?? draft.iconHex,
      bannerTextHex: _validHexOrNull(bannerTextCtrl.text) ?? draft.bannerTextHex,
    );

    try {
      isSaving = true;
      update([formId]);
      await _repo.save(draft);
      AppSnackbar.show('تم حفظ الهوية البصرية');
    } catch (e) {
      AppSnackbar.show('تعذر الحفظ: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update([formId]);
    }
  }

  void resetDefaults() {
    activePresetId = null;
    _hydrate(BrandingModel.defaults().copyWith(logoUrl: draft.logoUrl, brandName: draft.brandName));
    update([formId, previewId]);
  }

  /// Applies a curated fashion look while keeping the current logo + brand name.
  void applyPreset(BrandingStylePreset preset) {
    activePresetId = preset.id;
    final next = preset.style.copyWith(
      brandName: draft.brandName.isEmpty ? preset.style.brandName : draft.brandName,
      logoUrl: draft.logoUrl,
    );
    _hydrate(next);
    update([formId, previewId]);
    AppSnackbar.show('تم تطبيق ستايل ${preset.titleAr} — اضغط حفظ الهوية');
  }

  String? _validHexOrNull(String value) {
    final parsed = parseHexColor(value);
    if (parsed == null) return null;
    final hex = value.trim().replaceFirst('#', '').toUpperCase();
    return '#$hex';
  }
}
