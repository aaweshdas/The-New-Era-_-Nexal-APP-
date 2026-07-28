import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tailwind Colors match
  static const Color purple500 = Color(0xFFA855F7);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color cyan500 = Color(0xFF06B6D4);

  static const Color background = Color(0xFF000000); // Deep Space Black

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: background,
    primaryColor: purple500,
    colorScheme: const ColorScheme.dark(
      primary: purple500,
      secondary: pink500,
      tertiary: blue500,
      surface: Colors.black, // darker surface
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF000000),
      Color(0xFF0A0A1A),
      Color(0xFF000000),
      Color(0xFF0A0A14),
      Color(0xFF000000),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );
}
