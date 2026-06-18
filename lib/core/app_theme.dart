import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.red,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.red,
        secondary: AppColors.redL,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
    );
  }
}