import 'dart:js_interop';
import 'dart:typed_data';

@JS('theHatchBg')
external _BgApi? get _api;

extension type _BgApi._(JSObject _) implements JSObject {
  external JSPromise<JSUint8Array> removeBackground(JSUint8Array bytes, _BgOptions options);
}

extension type _BgOptions._(JSObject _) implements JSObject {
  external factory _BgOptions({double ratio, double margin, JSFunction? onProgress});
}

/// Bridge to `web/js/bg_removal.js`: removes the photo background in the browser and returns a PNG
/// with the product centered on pure white.
class BackgroundRemovalService {
  BackgroundRemovalService._();

  /// Product cards in the store app are 4:5.
  static const double productRatio = 0.8;
  static const double margin = 0.08;

  static bool get isAvailable => _api != null;

  /// [onProgress] reports the one-time model download (0-100).
  static Future<Uint8List> whiteBackground(
    Uint8List bytes, {
    double ratio = productRatio,
    void Function(int percent)? onProgress,
  }) async {
    final api = _api;
    if (api == null) throw 'خدمة تفريغ الخلفية غير محمّلة، أعد تحميل الصفحة';
    try {
      final result = await api
          .removeBackground(
            bytes.toJS,
            _BgOptions(
              ratio: ratio,
              margin: margin,
              onProgress: onProgress == null ? null : ((JSNumber p) => onProgress(p.toDartInt)).toJS,
            ),
          )
          .toDart;
      return result.toDart;
    } catch (e) {
      final message = '$e';
      if (message.contains('no subject')) throw 'لم يتم العثور على منتج واضح في الصورة';
      if (RegExp(r'\d{8,}').hasMatch(message) || message.contains('bad_alloc') || message.contains('OOM')) {
        throw 'نفدت ذاكرة المتصفح أثناء التفريغ. أغلق تبويبات أخرى وأعد المحاولة بصورة أصغر';
      }
      throw 'تعذر تفريغ الخلفية: $message';
    }
  }
}
