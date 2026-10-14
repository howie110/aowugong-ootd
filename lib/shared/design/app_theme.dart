import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppTheme {
  static ThemeData light() =>
      ThemeData(colorScheme: ColorSchemes.lightZinc, radius: 0.5);
}

/// Semantic app roles derived from the single shadcn color scheme.
class OotdColors {
  OotdColors.of(BuildContext context) : colors = Theme.of(context).colorScheme;
  final ColorScheme colors;
  Color get appBackground => colors.background;
  Color get foreground => colors.foreground;
  Color get cardSurface => colors.card;
  Color get cardBorder => colors.border;
  Color get mutedSurface => colors.muted;
  Color get mutedForeground => colors.mutedForeground;
  Color get selectedSurface => colors.primary;
  Color get selectedForeground => colors.primaryForeground;
  Color get subtleIcon => colors.mutedForeground;
  Color get subtleDivider => colors.border;
  Color get destructive => colors.destructive;
}
