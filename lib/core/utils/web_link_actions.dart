import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Web helpers for opening / copying links from the admin dashboard.
class WebLinkActions {
  WebLinkActions._();

  static void openExternal(String url) {
    if (url.trim().isEmpty) return;
    web.window.open(url, '_blank');
  }

  static Future<void> copyText(String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }
}
