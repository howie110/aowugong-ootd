import 'package:flutter/material.dart';

class OotdColors extends ThemeExtension<OotdColors> {
  const OotdColors({
    required this.cardSurface,
    required this.cardBorder,
    required this.subtleIcon,
    required this.accentWarm,
    required this.subtleDivider,
  });

  final Color cardSurface;
  final Color cardBorder;
  final Color subtleIcon;
  final Color accentWarm;
  final Color subtleDivider;

  static const light = OotdColors(
    cardSurface: Colors.white,
    cardBorder: Color(0xFFDCE6F6),
    subtleIcon: Color(0xFF5F7FB4),
    accentWarm: Color(0xFFB87E49),
    subtleDivider: Color(0xFFF0F4FA),
  );

  @override
  OotdColors copyWith({
    Color? cardSurface,
    Color? cardBorder,
    Color? subtleIcon,
    Color? accentWarm,
    Color? subtleDivider,
  }) {
    return OotdColors(
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleIcon: subtleIcon ?? this.subtleIcon,
      accentWarm: accentWarm ?? this.accentWarm,
      subtleDivider: subtleDivider ?? this.subtleDivider,
    );
  }

  @override
  OotdColors lerp(OotdColors? other, double t) {
    if (other is! OotdColors) return this;
    return OotdColors(
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleIcon: Color.lerp(subtleIcon, other.subtleIcon, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      subtleDivider: Color.lerp(subtleDivider, other.subtleDivider, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    const seedColor = Color(0xFF3C7BF4);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F7FD),
      extensions: const [OotdColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF3F7FD),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF183B73),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: selected ? 20 : 19);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final weight = states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500;
          return TextStyle(
            fontSize: 10.5,
            fontWeight: weight,
            letterSpacing: 0.1,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      dividerColor: const Color(0xFFDCE6F6),
    );
  }
}
