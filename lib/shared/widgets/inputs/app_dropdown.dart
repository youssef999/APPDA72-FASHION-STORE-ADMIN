import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;

  const AppDropdownItem(this.value, this.label);
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = DropdownButtonFormField<T>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      isExpanded: true,
      hint: hint == null ? null : Text(hint!, style: AppTextStyles.body2.copyWith(color: c.textDisabled)),
      dropdownColor: c.card,
      style: AppTextStyles.body2.copyWith(color: c.textPrimary),
      decoration: const InputDecoration(isDense: true),
      items: items
          .map((item) => DropdownMenuItem<T>(value: item.value, child: Text(item.label)))
          .toList(),
      onChanged: onChanged,
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        field,
      ],
    );
  }
}
