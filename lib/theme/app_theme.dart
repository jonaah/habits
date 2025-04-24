import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF50E3C2);
  static const Color accentColor = Color(0xFFFF9500);
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF8E8E93);
  static const Color streakColor = Color(0xFFFF3B30);
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14.0,
    color: subtitleColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: textColor,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: const CardTheme(
        color: cardColor,
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: headingStyle,
        titleLarge: titleStyle,
        titleMedium: subtitleStyle,
        bodyLarge: bodyStyle,
      ),
    );
  }
}