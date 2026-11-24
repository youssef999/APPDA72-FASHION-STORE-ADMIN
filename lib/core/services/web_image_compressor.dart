import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class CompressedImage {
  final Uint8List bytes;
  final String contentType;
  final int width;
  final int height;

  const CompressedImage({required this.bytes, required this.contentType, required this.width, required this.height});

  String get extension => switch (contentType) {
        'image/webp' => 'webp',
        'image/png' => 'png',
        _ => 'jpg',
      };
}

/// Re-encodes images with the browser's own canvas encoder: resizes, optionally flattens
/// transparency onto white, strips EXIF/metadata, and lowers quality until the target size.
/// Only `ImageUploadService` should call this.
class WebImageCompressor {
  WebImageCompressor._();

  static const double _qualityStep = 0.07;

  static Future<CompressedImage> compress(
    Uint8List input, {
    required int maxSide,
    required double quality,
    required double minQuality,
    required int targetBytes,
    bool preserveTransparency = false,
  }) async {
    final bitmap = await _decode(input);
    final scale = math.min(1.0, maxSide / math.max(bitmap.width, bitmap.height));
    final width = math.max(1, (bitmap.width * scale).round());
    final height = math.max(1, (bitmap.height * scale).round());

    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = width;
    canvas.height = height;
    // Always request an alpha-capable 2D context; white fill is applied only when
    // transparency is intentionally discarded (product photos).
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.globalCompositeOperation = 'copy';
    ctx.clearRect(0, 0, width, height);
    ctx.globalCompositeOperation = 'source-over';
    if (!preserveTransparency) {
      ctx
        ..fillStyle = '#FFFFFF'.toJS
        ..fillRect(0, 0, width, height);
    }
    ctx
      ..imageSmoothingEnabled = true
      ..imageSmoothingQuality = 'high'
      ..drawImage(bitmap, 0, 0, width, height);
    bitmap.close();

    if (preserveTransparency) {
      // Force PNG so alpha cannot be dropped (JPEG has no alpha).
      final blob = await _encode(canvas, 'image/png', 1);
      final buffer = await blob.arrayBuffer().toDart;
      return CompressedImage(
        bytes: buffer.toDart.asUint8List(),
        contentType: 'image/png',
        width: width,
        height: height,
      );
    }

    var type = 'image/webp';
    var q = quality;
    var blob = await _encode(canvas, type, q);
    if (blob.type != type) {
      type = 'image/jpeg';
      q = quality + 0.03;
      blob = await _encode(canvas, type, q);
    }
    while (blob.size > targetBytes && q - _qualityStep >= minQuality) {
      q -= _qualityStep;
      blob = await _encode(canvas, type, q);
    }
    final buffer = await blob.arrayBuffer().toDart;
    return CompressedImage(bytes: buffer.toDart.asUint8List(), contentType: type, width: width, height: height);
  }

  static Future<web.ImageBitmap> _decode(Uint8List bytes) async {
    final blob = web.Blob([bytes.toJS].toJS);
    try {
      return await web.window.createImageBitmap(blob).toDart;
    } catch (_) {
      throw 'تعذر قراءة الصورة، استخدم JPG أو PNG أو WebP';
    }
  }

  static Future<web.Blob> _encode(web.HTMLCanvasElement canvas, String type, double quality) {
    final completer = Completer<web.Blob>();
    canvas.toBlob(
      ((web.Blob? blob) {
        if (blob == null) {
          completer.completeError('تعذر ضغط الصورة');
        } else {
          completer.complete(blob);
        }
      }).toJS,
      type,
      quality.toJS,
    );
    return completer.future;
  }
}
