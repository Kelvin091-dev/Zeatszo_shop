import 'package:flutter/material.dart';

/// Central theme configuration for the Shopkeeper Dashboard app.
/// 
/// Design System Colors:
/// - Primary: Deep Purple (#4B39EF)
/// - Secondary: Teal Green (#39D2C0)
/// - Tertiary: Orange Coral (#EE8B60)
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Design System Colors
  static const Color primaryColor = Color(0xFF4B39EF);
  static const Color secondaryColor = Color(0xFF39D2C0);
  static const Color tertiaryColor = Color(0xFFEE8B60);
  static const Color alternateColor = Color(0xFFE0E3E7);

  // Text Colors
  static const Color primaryText = Color(0xFF14181B);
  static const Color secondaryText = Color(0xFF57636C);

  // Background Colors
  static const Color primaryBackground = Color(0xFFF1F4F8);
  static const Color secondaryBackground = Color(0xFFFFFFFF);

  // Accent Colors (with opacity)
  static const Color accent1 = Color(0x4C4B39EF);
  static const Color accent2 = Color(0x4D39D2C0);
  static const Color accent3 = Color(0x4DEE8B60);
  static const Color accent4 = Color(0xCCFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF249689);
  static const Color warning = Color(0xFFF9CF58);
  static const Color error = Color(0xFFFF5963);
  static const Color info = Color(0xFFFFFFFF);

  // Typography
  static const String fontFamily = 'Outfit';

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: error,
        surface: secondaryBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryText,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: primaryBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: secondaryBackground,
        foregroundColor: primaryText,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevationLow,
        color: secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(spacingS),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationMedium,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: alternateColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: alternateColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryText,
          fontFamily: fontFamily,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryText,
          fontFamily: fontFamily,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: secondaryText,
          fontFamily: fontFamily,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: secondaryText,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: alternateColor,
        thickness: 1,
        space: spacingM,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: error,
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: elevationLow,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(spacingS),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationMedium,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
      ),

      iconTheme: const IconThemeData(
        color: Color(0xFFB0B0B0),
        size: 24,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
        space: spacingM,
      ),
    );
  }
}

