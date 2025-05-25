// config/theme/app_theme.dart - SIMPLE VERSION
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App theme configurations with emoji support
class AppTheme {
  /// Light theme with emoji support
  static ThemeData get lightTheme {
    return ThemeData(
      // Base colors
      primaryColor: AppColors.primaryBlue,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        primaryContainer: AppColors.primaryBlueLight,
        secondary: AppColors.accentOrange,
        secondaryContainer: AppColors.accentOrangeLight,
        tertiary: AppColors.accentTeal,
        tertiaryContainer: AppColors.accentTealLight,
        error: AppColors.error,
        background: AppColors.backgroundLight,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onTertiary: AppColors.white,
        onError: AppColors.white,
        onBackground: AppColors.textDark,
        onSurface: AppColors.textDark,
      ),

      // SIMPLE FIX: Typography with emoji support using Google Fonts
      textTheme: _buildSimpleEmojiTextTheme(),

      // Component themes (keep your existing code)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.backgroundDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.backgroundDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        errorStyle: TextStyle(color: AppColors.error),
        hintStyle: TextStyle(color: AppColors.textLight),
      ),

      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.backgroundDark;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.backgroundDark;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.backgroundDark;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlueLight;
          }
          return AppColors.backgroundDark;
        }),
      ),

      tabBarTheme: TabBarTheme(
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.7),
        indicator: BoxDecoration(
          color: AppColors.accentOrange,
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMedium,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Additional settings
      scaffoldBackgroundColor: AppColors.backgroundLight,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
    );
  }

  /// SIMPLE: Build text theme with emoji support using Google Fonts (no downloads needed)
  static TextTheme _buildSimpleEmojiTextTheme() {
    // Get Inter font from Google Fonts (you already have this package)
    final baseTextTheme = GoogleFonts.interTextTheme();

    // Create a helper function to add emoji support to any text style
    TextStyle addEmojiSupport(TextStyle? style) {
      return (style ?? const TextStyle()).copyWith(
        fontFamilyFallback: const [
          // System emoji fonts (built into devices)
          'Apple Color Emoji', // iOS
          'Segoe UI Emoji', // Windows
          'Noto Color Emoji', // Android
          'Noto Emoji', // Android fallback
          'Symbola', // Linux
          'DejaVu Sans', // General fallback
        ],
      );
    }

    return TextTheme(
      headlineLarge: addEmojiSupport(baseTextTheme.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        height: 1.2,
        letterSpacing: -0.5,
      )),
      headlineMedium: addEmojiSupport(baseTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        height: 1.3,
        letterSpacing: -0.25,
      )),
      headlineSmall: addEmojiSupport(baseTextTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        height: 1.3,
      )),
      titleLarge: addEmojiSupport(baseTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.4,
      )),
      titleMedium: addEmojiSupport(baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.4,
      )),
      titleSmall: addEmojiSupport(baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.4,
      )),
      bodyLarge: addEmojiSupport(baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        color: AppColors.textDark,
        height: 1.5,
        letterSpacing: 0.15,
      )),
      bodyMedium: addEmojiSupport(baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.textDark,
        height: 1.5,
        letterSpacing: 0.25,
      )),
      bodySmall: addEmojiSupport(baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: AppColors.textMedium,
        height: 1.4,
        letterSpacing: 0.4,
      )),
      labelLarge: addEmojiSupport(baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        height: 1.4,
        letterSpacing: 0.1,
      )),
      labelMedium: addEmojiSupport(baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        height: 1.3,
        letterSpacing: 0.5,
      )),
      labelSmall: addEmojiSupport(baseTextTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMedium,
        height: 1.2,
        letterSpacing: 1.5,
      )),
    );
  }

  /// Dark theme (if needed later)
  static ThemeData get darkTheme {
    return lightTheme;
  }
}
