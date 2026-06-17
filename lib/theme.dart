import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

class KMColors {
  // Primary palette
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color secondary = Color(0xFF8BC34A);
  static const Color accent = Color(0xFFFFC107);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF2FFE9);
  static const Color backgroundDark = Color(0xFF121212);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Cards
  static const Color cardTint = Color(0xFFE8F5E9);
  static const Color cardDark = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color available = Color(0xFF4CAF50);
  static const Color unavailable = Color(0xFFE53935);
}

class KMSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class KMRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double card = 12.0;
  static const double chip = 20.0;
  static const double button = 12.0;
  static const double image = 10.0;
}

class KMShadow {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared text theme (Nunito for both light and dark)
// ─────────────────────────────────────────────────────────────────────────────

TextTheme _nunitoTextTheme(TextTheme base) =>
    GoogleFonts.nunitoTextTheme(base);

// ─────────────────────────────────────────────────────────────────────────────
// Shared component styles
// ─────────────────────────────────────────────────────────────────────────────

AppBarTheme _appBarTheme() => AppBarTheme(
      backgroundColor: KMColors.primary,
      foregroundColor: KMColors.textOnPrimary,
      elevation: 0,
      iconTheme: const IconThemeData(color: KMColors.textOnPrimary),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: KMColors.textOnPrimary,
      ),
    );

ElevatedButtonThemeData _elevatedButtonTheme() => ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KMColors.primary,
        foregroundColor: KMColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KMRadius.button),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );

OutlinedButtonThemeData _outlinedButtonTheme() => OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KMColors.primary,
        side: const BorderSide(color: KMColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KMRadius.button),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: KMColors.primary),
    );

FloatingActionButtonThemeData _fabTheme() =>
    const FloatingActionButtonThemeData(
      backgroundColor: KMColors.primary,
      foregroundColor: KMColors.textOnPrimary,
      elevation: 4,
    );

ChipThemeData _chipTheme({required bool dark}) => ChipThemeData(
      backgroundColor: dark ? KMColors.cardDark : KMColors.cardTint,
      selectedColor: KMColors.primary,
      disabledColor: dark ? Colors.white12 : KMColors.divider,
      labelStyle: TextStyle(
        color: dark ? Colors.white70 : KMColors.textPrimary,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      pressElevation: 2,
    );

InputDecorationTheme _inputDecorationTheme({required bool dark}) =>
    InputDecorationTheme(
      filled: true,
      fillColor: dark ? KMColors.surfaceDark : KMColors.surfaceLight,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KMRadius.md),
        borderSide: BorderSide(
          color: dark ? Colors.white24 : KMColors.divider,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KMRadius.md),
        borderSide: BorderSide(
          color: dark ? Colors.white24 : KMColors.divider,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KMRadius.md),
        borderSide:
            const BorderSide(color: KMColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KMRadius.md),
        borderSide: const BorderSide(color: KMColors.error),
      ),
      hintStyle: TextStyle(
        color: dark ? Colors.white38 : KMColors.textSecondary,
      ),
      labelStyle: TextStyle(
        color: dark ? Colors.white60 : KMColors.textSecondary,
      ),
    );

CardThemeData _cardTheme({required bool dark}) => CardThemeData(
      color: dark ? KMColors.cardDark : KMColors.cardTint,
      elevation: 2,
      shadowColor:
          dark ? Colors.black26 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KMRadius.card),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    );

SwitchThemeData _switchTheme() => SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? KMColors.primary
            : null,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? KMColors.primary.withValues(alpha: 0.4)
            : null,
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Light theme
// ─────────────────────────────────────────────────────────────────────────────

final ThemeData kmLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: KMColors.primary,
  scaffoldBackgroundColor: KMColors.backgroundLight,
  colorScheme: ColorScheme.fromSeed(
    seedColor: KMColors.primary,
    primary: KMColors.primary,
    secondary: KMColors.secondary,
    error: KMColors.error,
    brightness: Brightness.light,
  ).copyWith(surface: KMColors.surfaceLight),
  appBarTheme: _appBarTheme(),
  cardColor: KMColors.cardTint,
  cardTheme: _cardTheme(dark: false),
  elevatedButtonTheme: _elevatedButtonTheme(),
  outlinedButtonTheme: _outlinedButtonTheme(),
  textButtonTheme: _textButtonTheme(),
  floatingActionButtonTheme: _fabTheme(),
  chipTheme: _chipTheme(dark: false),
  inputDecorationTheme: _inputDecorationTheme(dark: false),
  switchTheme: _switchTheme(),
  dividerColor: KMColors.divider,
  dividerTheme: const DividerThemeData(
    color: KMColors.divider,
    thickness: 1,
    space: 1,
  ),
  listTileTheme: const ListTileThemeData(iconColor: KMColors.primary),
  iconTheme: const IconThemeData(color: KMColors.primary),
  textTheme: _nunitoTextTheme(ThemeData.light().textTheme),
);

// ─────────────────────────────────────────────────────────────────────────────
// Dark theme
// ─────────────────────────────────────────────────────────────────────────────

final ThemeData kmDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: KMColors.primary,
  scaffoldBackgroundColor: KMColors.backgroundDark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: KMColors.primary,
    primary: KMColors.primary,
    secondary: KMColors.secondary,
    error: KMColors.error,
    brightness: Brightness.dark,
  ).copyWith(surface: KMColors.surfaceDark),
  appBarTheme: _appBarTheme(),
  cardColor: KMColors.cardDark,
  cardTheme: _cardTheme(dark: true),
  elevatedButtonTheme: _elevatedButtonTheme(),
  outlinedButtonTheme: _outlinedButtonTheme(),
  textButtonTheme: _textButtonTheme(),
  floatingActionButtonTheme: _fabTheme(),
  chipTheme: _chipTheme(dark: true),
  inputDecorationTheme: _inputDecorationTheme(dark: true),
  switchTheme: _switchTheme(),
  dividerColor: Colors.white12,
  listTileTheme: const ListTileThemeData(iconColor: KMColors.primary),
  iconTheme: const IconThemeData(color: KMColors.primary),
  textTheme: _nunitoTextTheme(ThemeData.dark().textTheme),
);
