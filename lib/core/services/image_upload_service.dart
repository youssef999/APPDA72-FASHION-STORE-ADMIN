import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'web_image_compressor.dart';

// ---------------------------------------------------------------------------
// The only place in the dashboard that knows how images are compressed and where they are stored.
// To move to another provider (Cloudinary, S3, own server): implement [ImageUploader] and change
// [ImageUploadService.uploader]. Nothing else in the app needs to change.
// ---------------------------------------------------------------------------

/// Compression profile for one kind of image.
class ImageProfile {
  final int maxSide;
  final double quality;
  final double minQuality;
  final int targetBytes;

  const ImageProfile({required this.maxSide, required this.quality, required this.minQuality, required this.targetBytes});
}

enum ImageKind { product, category, branding }

/// Every upload setting in one place.
class ImageUploadConfig {
  ImageUploadConfig._();

  /// Files larger than this are rejected before any processing.
  static const int maxInputBytes = 15 * 1024 * 1024;

  static const ImageProfile product = ImageProfile(maxSide: 1200, quality: 0.72, minQuality: 0.5, targetBytes: 180 * 1024);
  static const ImageProfile category = ImageProfile(maxSide: 800, quality: 0.72, minQuality: 0.5, targetBytes: 120 * 1024);
  static const ImageProfile branding = ImageProfile(maxSide: 800, quality: 0.85, minQuality: 0.6, targetBytes: 120 * 1024);
  static const ImageProfile thumbnail = ImageProfile(maxSide: 400, quality: 0.7, minQuality: 0.5, targetBytes: 30 * 1024);

  /// Working copy used while cropping / removing the background; keeps editing fast on large camera photos.
  static const ImageProfile editing = ImageProfile(maxSide: 2400, quality: 0.92, minQuality: 0.92, targetBytes: 1 << 30);

  static ImageProfile profileOf(ImageKind kind) => switch (kind) {
        ImageKind.product => product,
        ImageKind.category => category,
        ImageKind.branding => branding,
      };

  static String folderOf(ImageKind kind, String ownerId) => switch (kind) {
        ImageKind.product => 'products/${ownerId.isEmpty ? 'new' : ownerId}',
        ImageKind.category => 'categories',
        ImageKind.branding => 'branding',
      };

  /// Long-lived browser/CDN caching; uploaded files are never overwritten (names are unique).
  static const String cacheControl = 'public, max-age=31536000, immutable';
}

/// Storage backend contract.
abstract class ImageUploader {
  /// Stores [bytes] at [path] and returns a public URL.
  Future<String> upload(Uint8List bytes, String path, String contentType);

  Future<void> delete(String url);
}

class FirebaseStorageUploader implements ImageUploader {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> upload(Uint8List bytes, String path, String contentType) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType, cacheControl: ImageUploadConfig.cacheControl));
    return ref.getDownloadURL();
  }

  @override
  Future<void> delete(String url) => _storage.refFromURL(url).delete();
}

class PickedImage {
  final String name;
  final Uint8List bytes;

  const PickedImage(this.name, this.bytes);
}

class UploadedImage {
  final String url;
  final String thumbnailUrl;
  final int originalBytes;
  final int uploadedBytes;

  const UploadedImage({required this.url, required this.thumbnailUrl, required this.originalBytes, required this.uploadedBytes});
}

class ImageUploadService {
  ImageUploadService._();

  /// The active storage backend.
  static final ImageUploader uploader = FirebaseStorageUploader();

  static Future<List<PickedImage>> pick({bool multiple = false}) async {
    final single = multiple ? null : await FilePicker.pickFile(type: FileType.image);
    final List<PlatformFile> files = multiple
        ? await FilePicker.pickFiles(type: FileType.image)
        : [if (single != null) single];
    final picked = <PickedImage>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.length > ImageUploadConfig.maxInputBytes) {
        throw 'حجم الصورة "${file.name}" أكبر من ${ImageUploadConfig.maxInputBytes ~/ (1024 * 1024)} ميجا';
      }
      picked.add(PickedImage(file.name, bytes));
    }
    return picked;
  }

  static Future<Uint8List> prepareForEditing(Uint8List bytes) async =>
      (await _compress(bytes, ImageUploadConfig.editing)).bytes;

  /// Compressed result for the size preview shown before uploading.
  static Future<CompressedImage> compress(Uint8List bytes, ImageKind kind) => _compress(bytes, ImageUploadConfig.profileOf(kind));

  static Future<UploadedImage> uploadProductImage(Uint8List bytes, String productId) =>
      _upload(bytes, ImageKind.product, productId);

  static Future<UploadedImage> uploadCategoryImage(Uint8List bytes) => _upload(bytes, ImageKind.category, '');

  /// Logo upload must keep alpha. Canvas re-encoding often flattens PNG transparency
  /// to white in browsers, so we upload the original PNG/WebP bytes whenever possible.
  static Future<UploadedImage> uploadBrandingLogo(Uint8List bytes) async {
    final originalType = _detectImageContentType(bytes);
    final CompressedImage main;
    if (originalType == 'image/png' || originalType == 'image/webp') {
      // Keep the source alpha channel untouched.
      main = CompressedImage(
        bytes: bytes,
        contentType: originalType!,
        width: 0,
        height: 0,
      );
    } else {
      // JPG has no alpha — convert to transparent-capable PNG without white fill.
      main = await WebImageCompressor.compress(
        bytes,
        maxSide: ImageUploadConfig.branding.maxSide,
        quality: ImageUploadConfig.branding.quality,
        minQuality: ImageUploadConfig.branding.minQuality,
        targetBytes: ImageUploadConfig.branding.targetBytes,
        preserveTransparency: true,
      );
    }

    // Reuse the same transparent file for the thumb URL (logos are already small).
    final folder = ImageUploadConfig.folderOf(ImageKind.branding, '');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final path = '$folder/$stamp.${main.extension}';
    final url = await uploader.upload(main.bytes, path, main.contentType);
    return UploadedImage(
      url: url,
      thumbnailUrl: url,
      originalBytes: bytes.length,
      uploadedBytes: main.bytes.length,
    );
  }

  static String? _detectImageContentType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    return null;
  }

  static Future<void> delete(String url) => uploader.delete(url);

  static Future<UploadedImage> _upload(Uint8List bytes, ImageKind kind, String ownerId) async {
    final main = await compress(bytes, kind);
    final thumb = await _compress(main.bytes, ImageUploadConfig.thumbnail);
    final folder = ImageUploadConfig.folderOf(kind, ownerId);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final urls = await Future.wait([
      uploader.upload(main.bytes, '$folder/$stamp.${main.extension}', main.contentType),
      uploader.upload(thumb.bytes, '$folder/thumbs/$stamp.${thumb.extension}', thumb.contentType),
    ]);
    return UploadedImage(url: urls[0], thumbnailUrl: urls[1], originalBytes: bytes.length, uploadedBytes: main.bytes.length);
  }

  static Future<CompressedImage> _compress(Uint8List bytes, ImageProfile profile) => WebImageCompressor.compress(
        bytes,
        maxSide: profile.maxSide,
        quality: profile.quality,
        minQuality: profile.minQuality,
        targetBytes: profile.targetBytes,
      );
}
