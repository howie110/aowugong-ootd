import 'package:flutter/material.dart';

class OotdColors extends ThemeExtension<OotdColors> {
  const OotdColors({
    required this.appBackground,
    required this.foreground,
    required this.cardSurface,
    required this.cardBorder,
    required this.mutedSurface,
    required this.mutedForeground,
    required this.selectedSurface,
    required this.selectedForeground,
    required this.subtleIcon,
    required this.accentWarm,
    required this.subtleDivider,
    required this.destructive,
    required this.ring,
  });

  final Color appBackground;
  final Color foreground;
  final Color cardSurface;
  final Color cardBorder;
  final Color mutedSurface;
  final Color mutedForeground;
  final Color selectedSurface;
  final Color selectedForeground;
  final Color subtleIcon;
  final Color accentWarm;
  final Color subtleDivider;
  final Color destructive;
  final Color ring;

  static const light = OotdColors(
    appBackground: Color(0xFFFAFAFA),
    foreground: Color(0xFF111827),
    cardSurface: Colors.white,
    cardBorder: Color(0xFFE5E7EB),
    mutedSurface: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717A),
    selectedSurface: Color(0xFF111827),
    selectedForeground: Colors.white,
    subtleIcon: Color(0xFF64748B),
    accentWarm: Color(0xFFA16207),
    subtleDivider: Color(0xFFF1F5F9),
    destructive: Color(0xFFDC2626),
    ring: Color(0xFF94A3B8),
  );

  @override
  OotdColors copyWith({
    Color? appBackground,
    Color? foreground,
    Color? cardSurface,
    Color? cardBorder,
    Color? mutedSurface,
    Color? mutedForeground,
    Color? selectedSurface,
    Color? selectedForeground,
    Color? subtleIcon,
    Color? accentWarm,
    Color? subtleDivider,
    Color? destructive,
    Color? ring,
  }) {
    return OotdColors(
      appBackground: appBackground ?? this.appBackground,
      foreground: foreground ?? this.foreground,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      selectedSurface: selectedSurface ?? this.selectedSurface,
      selectedForeground: selectedForeground ?? this.selectedForeground,
      subtleIcon: subtleIcon ?? this.subtleIcon,
      accentWarm: accentWarm ?? this.accentWarm,
      subtleDivider: subtleDivider ?? this.subtleDivider,
      destructive: destructive ?? this.destructive,
      ring: ring ?? this.ring,
    );
  }

  @override
  OotdColors lerp(OotdColors? other, double t) {
    if (other is! OotdColors) return this;
    return OotdColors(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      selectedForeground:
          Color.lerp(selectedForeground, other.selectedForeground, t)!,
      subtleIcon: Color.lerp(subtleIcon, other.subtleIcon, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      subtleDivider: Color.lerp(subtleDivider, other.subtleDivider, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    const seedColor = Color(0xFF111827);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: OotdColors.light.selectedSurface,
      onPrimary: OotdColors.light.selectedForeground,
      secondary: const Color(0xFF475569),
      onSecondary: Colors.white,
      surface: OotdColors.light.cardSurface,
      onSurface: OotdColors.light.foreground,
      outline: const Color(0xFFD4D4D8),
      outlineVariant: OotdColors.light.cardBorder,
      error: OotdColors.light.destructive,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OotdColors.light.appBackground,
      extensions: const [OotdColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: OotdColors.light.appBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        titleSpacing: 20,
        titleTextStyle: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 27,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          height: 1.1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE4E4E7);
            }
            return OotdColors.light.selectedSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF9CA3AF);
            }
            return OotdColors.light.selectedForeground;
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outline)),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: OotdColors.light.selectedSurface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 62,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: OotdColors.light.mutedSurface,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 21 : 20,
            color: selected
                ? OotdColors.light.foreground
                : OotdColors.light.mutedForeground,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final weight = states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500;
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? OotdColors.light.foreground
                : OotdColors.light.mutedForeground,
            fontSize: 11,
            fontWeight: weight,
            letterSpacing: 0,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: OotdColors.light.ring, width: 1.2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      dividerColor: OotdColors.light.subtleDivider,
    );
  }
}
