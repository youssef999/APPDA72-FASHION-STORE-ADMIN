import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';

class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  const AppSearchField({super.key, required this.hint, required this.onChanged, this.width = 280});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body2.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: Icon(AppIcons.search, size: AppIconSize.md, color: c.textSecondary),
        ),
      ),
    );
  }
}
