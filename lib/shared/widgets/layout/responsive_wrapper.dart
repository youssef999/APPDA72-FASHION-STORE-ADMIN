import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Lays children side by side (with [flex] weights) when wide enough, stacked otherwise.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;
  final double breakpoint;

  const ResponsiveRow({super.key, required this.children, this.flex, this.breakpoint = 900});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(flex: flex?[i] ?? 1, child: children[i]),
          ],
        ],
      );
    });
  }
}
