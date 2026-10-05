import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepPurple,
        primary: AppColors.deepPurple,
        secondary: AppColors.rose,
        tertiary: AppColors.lavender,
        surface: AppColors.white,
        onSurface: AppColors.charcoal,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );
    final body = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.charcoal,
      displayColor: AppColors.charcoal,
    );
    final serif = GoogleFonts.playfairDisplayTextTheme(body);
    final textTheme = body.copyWith(
      displayLarge: serif.displayLarge,
      displayMedium: serif.displayMedium,
      displaySmall: serif.displaySmall,
      headlineLarge: serif.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: serif.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: serif.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: serif.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.charcoal,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepPurple,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepPurple,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.lavender, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.lavenderSoft,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.charcoal),
        checkmarkColor: AppColors.deepPurple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.lavenderSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.deepPurple,
        thumbColor: AppColors.deepPurple,
        inactiveTrackColor: AppColors.lavenderSoft,
      ),
    );
  }
}
