import 'package:flutter/material.dart';

import '../../../../shared/design/app_theme.dart';

class CompactOptionGroup<T> extends StatelessWidget {
  const CompactOptionGroup({
    super.key,
    required this.options,
    required this.isSelected,
    required this.labelBuilder,
    required this.onTap,
  });

  final List<T> options;
  final bool Function(T value) isSelected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in options)
          CompactOptionButton(
            label: labelBuilder(option),
            selected: isSelected(option),
            onTap: () => onTap(option),
          ),
      ],
    );
  }
}

class CompactOptionButton extends StatelessWidget {
  const CompactOptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ootd = Theme.of(context).extension<OotdColors>() ?? OotdColors.light;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? ootd.selectedSurface : ootd.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ootd.selectedSurface : ootd.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(
              label,
              style: TextStyle(
                color: selected ? ootd.selectedForeground : ootd.foreground,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
