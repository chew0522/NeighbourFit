import 'package:flutter/material.dart';

// Warm leaf-green palette. Green is the main colour (buttons, selected states,
// progress). The soft yellow is only a highlight (AI bubble, create button,
// badges), and the cream background keeps everything warm.
const kPrimary = Color(0xFF3A7D44); // leaf green: buttons, selected tab, app name
const kGreen = Color(0xFF5FA463); // lighter leaf: progress bars, small accents
const kAccent = Color(0xFFF6D36B); // light warm yellow: highlights only
const kAccentSoft = Color(0xFFFFF3CC); // pale butter tint behind accent icons
const kAccentDark = Color(0xFF9A6A06); // amber for icons and text on light backgrounds
const kBackground = Color(0xFFFAF6EA); // warm cream page background
const kText = Color(0xFF26302A); // warm dark green-grey text
const kSurfaceGreen = Color(0xFFE4F0DA); // soft sage: chips, chosen and done states
const kMuted = Color(0xFF6F6B5E); // warm grey secondary text
const kBorder = Color(0xFFDDD6C3); // warm outline
const kClay = Color(0xFFB5651D); // earthy supporting colour
const kClaySoft = Color(0xFFF8E8D6);

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
    // Main action: green with white text. Yellow is kept for highlights.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kText,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: kBorder),
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
    dividerTheme: const DividerThemeData(color: kBorder, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: kSurfaceGreen,
      labelStyle: const TextStyle(fontSize: 15, color: kText),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: kBorder)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
