import 'package:flutter/material.dart';

class AppTheme {
  static const black = Color(0xFF050505);
  static const surface = Color(0xFF111111);
  static const surface2 = Color(0xFF181818);
  static const gold = Color(0xFFFFC857);
  static const gold2 = Color(0xFFFFD76A);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x22FFC857)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0x33FFC857),
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        thumbColor: gold2,
      ),
    );
  }
}
