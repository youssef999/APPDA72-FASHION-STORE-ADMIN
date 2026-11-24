import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Labelled form field; the decoration comes from the app theme.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.textDirection,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: controller,
          maxLines: obscureText ? 1 : maxLines,
          minLines: obscureText ? 1 : minLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          readOnly: readOnly,
          textDirection: textDirection,
          cursorColor: c.secondary,
          style: AppTextStyles.body1.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: AppIconSize.md, color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}
