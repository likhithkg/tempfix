import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KMColors {
  static const Color primary = Color(0xFF4CAF50); // Main green
  static const Color secondary = Color(0xFF8BC34A); // Light green
  static const Color backgroundLight = Color(0xFFF2FFE9);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardTint = Color(0xFFE8F5E9);
}

final ThemeData kmLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: KMColors.primary,
  scaffoldBackgroundColor: KMColors.backgroundLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: KMColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: KMColors.cardTint,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: KMColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: GoogleFonts.nunitoTextTheme(), // ✅ apply custom font
);

final ThemeData kmDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: KMColors.primary,
  scaffoldBackgroundColor: KMColors.backgroundDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: KMColors.primary,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: KMColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme:GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme), // ✅ dark mode font
);
