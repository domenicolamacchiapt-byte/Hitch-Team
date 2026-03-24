import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: const Color(0xFFFF9800), // Hitch Orange
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF9800),
        secondary: Color(0xFFFF9800),
        surface: Color(0xFF161616),
      ),
      cardColor: const Color(0xFF161616),
      dividerColor: Colors.white24,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
