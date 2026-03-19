// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light
  static const bg             = Color(0xFFF2F2F7);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF2F2F7);
  static const border         = Color(0xFFE5E5EA);
  static const accent         = Color(0xFF007AFF);
  static const accentLight    = Color(0xFF007AFF);
  static const green          = Color(0xFF34C759);
  static const red            = Color(0xFFFF3B30);
  static const orange         = Color(0xFFFF9500);
  static const blue           = Color(0xFF007AFF);
  static const textPrimary    = Color(0xFF000000);
  static const textSecondary  = Color(0xFF3C3C43);
  static const textMuted      = Color(0xFF8E8E93);
  static const separator      = Color(0xFFC6C6C8);

  // Dark mode semantic helpers
  static Color bg_(bool dark)             => dark ? const Color(0xFF000000)   : bg;
  static Color surface_(bool dark)        => dark ? const Color(0xFF1C1C1E)   : surface;
  static Color surfaceElevated_(bool dark)=> dark ? const Color(0xFF2C2C2E)   : surfaceElevated;
  static Color border_(bool dark)         => dark ? const Color(0xFF38383A)   : border;
  static Color accent_(bool dark)         => dark ? const Color(0xFF0A84FF)   : accent;
  static Color green_(bool dark)          => dark ? const Color(0xFF30D158)   : green;
  static Color red_(bool dark)            => dark ? const Color(0xFFFF453A)   : red;
  static Color orange_(bool dark)         => dark ? const Color(0xFFFF9F0A)   : orange;
  static Color textPrimary_(bool dark)    => dark ? Colors.white              : textPrimary;
  static Color textSecondary_(bool dark)  => dark ? const Color(0xFFEBEBF5)   : textSecondary;
  static Color textMuted_(bool dark)      => dark ? const Color(0xFF8E8E93)   : textMuted;

  static TextTheme _textTheme(bool dark) {
    final base = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final primary = dark ? Colors.white : textPrimary;
    final secondary = dark ? const Color(0xFFEBEBF5) : textSecondary;
    final muted = const Color(0xFF8E8E93);
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge:  GoogleFonts.inter(color: primary, fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(color: primary, fontSize: 28, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(color: primary, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium:GoogleFonts.inter(color: primary, fontSize: 17, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.inter(color: primary, fontSize: 17, fontWeight: FontWeight.w500),
      bodyLarge:     GoogleFonts.inter(color: primary, fontSize: 17),
      bodyMedium:    GoogleFonts.inter(color: secondary, fontSize: 15),
      labelSmall:    GoogleFonts.inter(color: muted, fontSize: 12),
    );
  }

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(
          primary: accent, secondary: green, surface: surface, error: red),
        textTheme: _textTheme(false),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
              color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: accent),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surface, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: separator)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: separator)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: accent, width: 1.5)),
          hintStyle: const TextStyle(color: textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerColor: separator,
        dividerTheme: const DividerThemeData(color: separator, thickness: 0.5),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF), secondary: Color(0xFF30D158),
          surface: Color(0xFF1C1C1E), error: Color(0xFFFF453A)),
        textTheme: _textTheme(true),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1C1C1E),
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: Color(0xFF0A84FF)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          selectedItemColor: Color(0xFF0A84FF),
          unselectedItemColor: Color(0xFF8E8E93),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C1E), elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF38383A))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF38383A))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5)),
          hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerColor: const Color(0xFF38383A),
        dividerTheme: const DividerThemeData(color: Color(0xFF38383A), thickness: 0.5),
      );
}
