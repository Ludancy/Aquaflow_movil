import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Dark Colors
  static const Color backgroundDark = Color(0xFF09121F); // Navy main background
  static const Color cardDark = Color(0xFF111E2E); // Darker blue card background
  static const Color surfaceDark = Color(0xFF111E2E); // Surface dark color
  static const Color primaryBlue = Color(0xFF3498DB); // Bright sky blue accent
  
  static const Color borderDark = Color(0xFF1E2D3D); // Border/Divider dark color
  static const Color textWhite = Color(0xFFF8FAFC); // High contrast text
  static const Color textMuted = Color(0xFF94A3B8); // Low contrast text/subtitles
  
  static const Color success = Color(0xFF10B981); // Emerald green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Orange

  // Dark Theme configuration used globally
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryBlue,
        surface: cardDark,
        background: backgroundDark,
        onPrimary: Colors.white,
        onSurface: textWhite,
        onBackground: textWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textWhite, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textWhite),
        bodyMedium: const TextStyle(color: textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textWhite,
          side: const BorderSide(color: borderDark, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Backwards compatibility role themes (now both unified dark-themed)
  static ThemeData get clientTheme => darkTheme;
  static ThemeData get driverTheme => darkTheme.copyWith(
    // We can add a slightly different tint for driver buttons if desired, but let's keep it cohesive
    primaryColor: primaryBlue,
  );

  static Gradient get backgroundGradient => const LinearGradient(
    colors: [backgroundDark, Color(0xFF070D16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
