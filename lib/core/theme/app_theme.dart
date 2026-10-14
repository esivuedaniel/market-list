import 'package:flutter/material.dart';
import 'package:market_list/core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const Color lightPrimary = Color(0xFFF57C00);
  static const Color lightScaffold = Color(0xFFFFFBF7);
  static const Color darkScaffold = Color(0xFF141210);

  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFF57C00),
        onPrimary: const Color(0xFF1A1A1A),
        primaryContainer: const Color(0xFFFFE0B2),
        onPrimaryContainer: const Color(0xFF3E2000),
        secondary: const Color(0xFF795548),
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF5EDE4),
        onSurface: const Color(0xFF1C1B1A),
        onSurfaceVariant: const Color(0xFF5E5750),
        outline: const Color(0xFF85776A),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF322F2C),
        onInverseSurface: const Color(0xFFF6EFE8),
        inversePrimary: const Color(0xFFFFB74D),
      );

  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFFB74D),
        onPrimary: const Color(0xFF3E2000),
        primaryContainer: const Color(0xFF7A3E00),
        onPrimaryContainer: const Color(0xFFFFE0B2),
        secondary: const Color(0xFFBCAAA4),
        surface: const Color(0xFF1C1917),
        surfaceContainerHighest: const Color(0xFF2A2622),
        onSurface: const Color(0xFFEAE1D9),
        onSurfaceVariant: const Color(0xFFC4B8AB),
        outline: const Color(0xFF9C8F80),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFEAE1D9),
        onInverseSurface: const Color(0xFF1C1917),
        inversePrimary: const Color(0xFF8F4100),
      );

  static ThemeData get light {
    final colors = lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: lightScaffold,
      extensions: const [AppColors.light],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFB45200), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(color: colors.onInverseSurface),
        actionTextColor: colors.inversePrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.light.primaryText,
          side: BorderSide(color: colors.outline, width: 1),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.light.primaryText,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colors = darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: darkScaffold,
      extensions: const [AppColors.dark],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFFFB74D), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(color: colors.onInverseSurface),
        actionTextColor: colors.inversePrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark.primaryText,
          side: BorderSide(color: colors.outline, width: 1),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dark.primaryText,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
