import 'package:flutter/material.dart';

class AppTheme {
  // Exact colors from your reference image
  static const Color primaryGreen = Color(0xFF0D2A1C); // Exact React dark green
  static const Color accentLime = Color(0xFFA3E635);   // Exact React lime-400
  static const Color scaffoldBg = Color(0xFFF9FAFB);  // Exact React gray-50
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: accentLime,
        surface: white,
      ),
      fontFamily: 'Inter', // Modern typography
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
