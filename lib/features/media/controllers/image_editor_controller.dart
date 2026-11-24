import 'dart:async';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:get/get.dart';
import '../../../core/services/background_removal_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../widgets/image_editor_dialog.dart';

/// Pick → (optional) crop → (optional) white background → compress → upload, one image at a time.
class ImageEditorController extends GetxController {
  static const String previewId = 'editor_preview';
  static const String toolsId = 'editor_tools';

  final ImageKind kind;
  final String ownerId;
  final List<PickedImage> queue;

  ImageEditorController._(this.kind, this.ownerId, this.queue);

  /// Opens the picker and the editor; resolves with everything that was uploaded.
  static Future<List<UploadedImage>> pickEditUpload({
    required ImageKind kind,
    String ownerId = '',
    bool multiple = false,
  }) async {
    final picked = await ImageUploadService.pick(multiple: multiple);
    if (picked.isEmpty) return const [];
    final controller = Get.put(ImageEditorController._(kind, ownerId, picked));
    await Get.dialog<void>(const ImageEditorDialog(), barrierDismissible: false);
    final uploaded = List<UploadedImage>.from(controller.uploaded);
    await Get.delete<ImageEditorController>(force: true);
    return uploaded;
  }

  final CropController cropController = CropController();
  final List<Uint8List> _history = [];
  final List<UploadedImage> uploaded = [];

  int index = 0;
  Uint8List? current;
  int originalSize = 0;
  int? compressedSize;
  bool isPreparing = true;
  bool isCropping = false;
  double? cropRatio = 0.8;
  bool isRemovingBg = false;
  int? modelProgress;
  bool isUploading = false;
  int _previewToken = 0;

  bool get canUndo => _history.isNotEmpty;
  bool get isBusy => isPreparing || isRemovingBg || isUploading;
  bool get isLast => index >= queue.length - 1;
  String get fileName => queue[index].name;
  double get outputRatio => kind == ImageKind.product ? BackgroundRemovalService.productRatio : 0;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isPreparing = true;
    isCropping = false;
    _history.clear();
    compressedSize = null;
    update();
    final source = queue[index].bytes;
    originalSize = source.length;
    try {
      current = await ImageUploadService.prepareForEditing(source);
    } catch (e) {
      AppSnackbar.show('$e', type: AppSnackbarType.error);
      current = null;
    }
    isPreparing = false;
    update();
    _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    final bytes = current;
    if (bytes == null) return;
    final token = ++_previewToken;
    compressedSize = null;
    update([previewId]);
    try {
      final result = await ImageUploadService.compress(bytes, kind);
      if (token != _previewToken) return;
      compressedSize = result.bytes.length;
    } catch (_) {
      compressedSize = null;
    }
    update([previewId]);
  }

  void _replace(Uint8List next) {
    _history.add(current!);
    current = next;
    update();
    _refreshPreview();
  }

  void undo() {
    if (_history.isEmpty) return;
    current = _history.removeLast();
    update();
    _refreshPreview();
  }

  void startCrop() {
    isCropping = true;
    update();
  }

  void cancelCrop() {
    isCropping = false;
    update();
  }

  void setCropRatio(double? ratio) {
    cropRatio = ratio;
    cropController.aspectRatio = ratio;
    update([toolsId]);
  }

  void applyCrop() => cropController.crop();

  void onCropped(CropResult result) {
    isCropping = false;
    switch (result) {
      case CropSuccess(:final croppedImage):
        _replace(croppedImage);
      case CropFailure(:final cause):
        update();
        AppSnackbar.show('تعذر قص الصورة: $cause', type: AppSnackbarType.error);
    }
  }

  Future<void> removeBackground() async {
    final bytes = current;
    if (bytes == null || isBusy) return;
    isRemovingBg = true;
    modelProgress = null;
    update();
    try {
      final result = await BackgroundRemovalService.whiteBackground(
        bytes,
        ratio: outputRatio,
        onProgress: (p) {
          modelProgress = p;
          update([toolsId]);
        },
      );
      isRemovingBg = false;
      _replace(result);
    } catch (e) {
      isRemovingBg = false;
      update();
      AppSnackbar.show('$e', type: AppSnackbarType.error);
    }
  }

  Future<void> uploadCurrent() async {
    final bytes = current;
    if (bytes == null || isBusy) return;
    isUploading = true;
    update();
    try {
      uploaded.add(await _uploadBytes(bytes));
      _next();
    } catch (e) {
      isUploading = false;
      update();
      AppSnackbar.show('تعذر رفع الصورة: $e', type: AppSnackbarType.error);
    }
  }

  /// Uploads this and every remaining image without further edits (still compressed).
  Future<void> uploadRemaining() async {
    if (isBusy) return;
    isUploading = true;
    update();
    try {
      uploaded.add(await _uploadBytes(current ?? queue[index].bytes));
      for (var i = index + 1; i < queue.length; i++) {
        uploaded.add(await _uploadBytes(queue[i].bytes));
      }
      _finish();
    } catch (e) {
      isUploading = false;
      update();
      AppSnackbar.show('تعذر رفع الصور: $e', type: AppSnackbarType.error);
    }
  }

  void skip() => _next();

  void close() => _finish();

  Future<UploadedImage> _uploadBytes(Uint8List bytes) => kind == ImageKind.product
      ? ImageUploadService.uploadProductImage(bytes, ownerId)
      : ImageUploadService.uploadCategoryImage(bytes);

  void _next() {
    isUploading = false;
    if (isLast) return _finish();
    index++;
    _load();
  }

  void _finish() {
    if (uploaded.isNotEmpty) {
      final before = uploaded.fold<int>(0, (s, u) => s + u.originalBytes);
      final after = uploaded.fold<int>(0, (s, u) => s + u.uploadedBytes);
      AppSnackbar.show('تم رفع ${uploaded.length} صورة • الحجم من ${formatBytes(before)} إلى ${formatBytes(after)}');
    }
    Get.back<void>();
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / 1024).round()}KB';
  }
}
