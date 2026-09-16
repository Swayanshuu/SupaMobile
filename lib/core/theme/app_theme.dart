import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final isDark = brightness == Brightness.dark;
    
    // Static colors for theme data init (we will still use context-aware ones for widgets)
    final bgBase = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA);
    final bgSurface = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFEDEDED) : const Color(0xFF1C1C1C);
    final textSecondary = isDark ? const Color(0xFF9A9A9A) : const Color(0xFF495057);
    final textMuted = isDark ? const Color(0xFF636363) : const Color(0xFFADB5BD);
    final borderDefault = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE9ECEF);

    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: isDark 
        ? ColorScheme.dark(
           primary: AppColors.supaGreen,
           secondary: AppColors.supaGreenDark,
           surface: bgSurface.withOpacity(0.8),
           error: AppColors.colorError,
           onPrimary: bgBase,
           onSurface: textPrimary,
          )
        : ColorScheme.light(
           primary: AppColors.supaGreen,
           secondary: AppColors.supaGreenDark,
           surface: bgSurface.withOpacity(0.9),
           error: AppColors.colorError,
           onPrimary: Colors.white,
           onSurface: textPrimary,
          ),
      textTheme: interTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textSecondary),
        titleTextStyle: interTextTheme.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(
            color: borderDefault,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgBase,
        hintStyle: interTextTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: interTextTheme.bodyMedium?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderDefault)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderDefault)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.supaGreen)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.colorError)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.supaGreen,
          foregroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderDefault, width: 1),
        ),
      ),
    );
  }

  static TextStyle get codeStyle => GoogleFonts.jetBrainsMono(color: AppColors.supaGreen);

  // Background Helper for Solid Background
  static Widget buildBackground({required Widget child, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      child: child,
    );
  }
}

