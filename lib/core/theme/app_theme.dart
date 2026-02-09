import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6750A4);
  static const _secondaryColor = Color(0xFF625B71);
  static const _tertiaryColor = Color(0xFF7D5260);

  // Standard Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Low Stimulation Theme (Accesibility)
  // - Softer colors
  // - Less contrast or specific calm palettes
  // - Standard readable fonts (already Inter, but maybe larger or more spaced in specific widgets)
  static ThemeData get lowStimulationTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5D737E), // Muted Blue/Grey
        brightness: Brightness.light,
        background: const Color(0xFFF0F4F8), // Soft white/grey
        surface: const Color(0xFFFFFFFF),
        primary: const Color(0xFF5D737E),
        secondary: const Color(0xFF8FA9BC),
      ),
      textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme(), // Accessible font
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFF0F4F8),
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Flat design for low stim
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      // Disable splashes/ripples ideally, but here we set colors
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
