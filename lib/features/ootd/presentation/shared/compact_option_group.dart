import 'package:aowugong_ootd/shared/design/app_ui.dart';

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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: SelectedButton(
        value: selected,
        onChanged: (_) => onTap(),
        style: const ButtonStyle.outline(),
        selectedStyle: const ButtonStyle.primary(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(label),
          ],
        ),
      ),
    );
  }
}
