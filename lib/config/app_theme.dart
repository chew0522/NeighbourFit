import 'package:flutter/material.dart';

const kPrimary = Color(0xFF1F7A52); // deep forest green: app bar, selected tab
const kGreen = Color(0xFF2E9E6B); // icons, progress bars, accents
const kAccent = Color(0xFFE07A5F); // muted terracotta: AI bubble, people actions
const kBackground = Color(0xFFF7F1E8); // warm cream page background
const kText = Color(0xFF1F2A37); // body text
const kSurfaceGreen = Color(0xFFD8F0E3); // cards, chips, completed states
const kMuted = Color(0xFF6B7280);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    primary: kPrimary,
    secondary: kAccent,
    surface: Colors.white,
  );
  const radius = BorderRadius.all(Radius.circular(14));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: kText),
      bodyMedium: TextStyle(fontSize: 16, color: kText),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kText),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    // Light, clean app bars (TikTok-style): cream background, dark text.
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Main action: orange with dark text (never white on orange).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: kText,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: kSurfaceGreen,
      labelStyle: const TextStyle(fontSize: 15, color: kText),
      side: const BorderSide(color: Color(0xFFD1D5DB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
