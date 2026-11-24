import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';

/// Product/category photo; images bundled inside the mobile app ("assets/...") can't load here.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final double radius;

  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = Container(
      color: c.background,
      alignment: Alignment.center,
      child: Tooltip(
        message: url.isEmpty ? 'لا توجد صورة' : 'صورة داخل التطبيق: $url',
        child: Icon(AppIcons.image, color: c.textDisabled, size: width < 60 ? AppIconSize.md : AppIconSize.xl),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                // Storage and many CDNs send no CORS headers; an <img> element still displays them.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => placeholder,
                loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
              )
            : placeholder,
      ),
    );
  }
}
