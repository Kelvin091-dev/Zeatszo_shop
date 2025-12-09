import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF4B39EF);
  static const secondary = Color(0xFF39D2C0);
  static const tertiary = Color(0xFFEE8B60);
  static const primaryBackground = Color(0xFFF1F4F8);
  static const secondaryBackground = Color(0xFFFFFFFF);
  static const success = Color(0xFF249689);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFFF5963);
}

class AppTheme {
  static TextTheme textTheme(Brightness b) {
    final base = b == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    return GoogleFonts.interTightTextTheme(base);
  }
  static ThemeData get light => ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.secondaryBackground,
        ),
        textTheme: textTheme(Brightness.light),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
        cardTheme: const CardTheme(color: AppColors.secondaryBackground, elevation: 2, margin: EdgeInsets.all(8)),
      );
  static ThemeData get dark => ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark, primary: AppColors.primary, secondary: AppColors.secondary, error: AppColors.error),
        textTheme: textTheme(Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
      );
}
