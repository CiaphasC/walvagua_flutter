import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const lightPrimary = Color(0xFFC9003E);
  static const lightAccent = Color(0xFFE53965);
  static const lightSecondary = Color(0xFFFF9800);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightBottomNavigation = Color(0xFFEFF4F8);
  static const lightSearchBar = Color(0xFFFFE4EC);
  static const lightTextDefault = Color(0xFFC9003E);
  static const lightFabBackground = Color(0xFFFFFFFF);
  static const lightFabIcon = Color(0xFFC9003E);

  static const darkPrimary = Color(0xFFAB0035);
  static const darkBackground = Color(0xFF1C1E22);
  static const darkBottomNavigation = Color(0xFF222D36);
  static const darkSearchBar = Color(0xFF222D36);
  static const darkTextDefault = Color(0xFF97002F);
  static const darkFabBackground = Color(0xFF384756);
  static const darkFabIcon = Color(0xFF480016);

  static const shimmerBase = Color(0xFFBCBEC1);
  static const greySoft = Color(0xFFE0E0E0);
  static const separator = Color(0xFFefefef);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      surfaceTint: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightAccent,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightSecondary,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.lightAccent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.lightAccent,
      onTertiaryContainer: Colors.white,
      error: Colors.red.shade700,
      onError: Colors.white,
      errorContainer: Colors.red.shade100,
      onErrorContainer: Colors.red.shade900,
      surface: AppColors.lightBackground,
      onSurface: Colors.black87,
      // ignore: deprecated_member_use
      surfaceVariant: const Color(0xFFF2F2F2),
      onSurfaceVariant: Colors.grey.shade700,
      outline: Colors.grey.shade400,
      outlineVariant: Colors.grey.shade300,
      shadow: Colors.black26,
      scrim: Colors.black45,
      inverseSurface: const Color(0xFF121212),
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.lightTextDefault,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'WallVagua',
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        foregroundColor: AppColors.lightTextDefault,
        centerTitle: false,
      ),
      textTheme: Typography.material2021().black.apply(fontFamily: 'WallVagua'),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBottomNavigation,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextDefault.withAlpha((0.6 * 255).round()),
        showUnselectedLabels: true,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.lightPrimary,
        labelColor: AppColors.lightPrimary,
        unselectedLabelColor: Colors.black54,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightFabBackground,
        foregroundColor: AppColors.lightFabIcon,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSearchBar,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      surfaceTint: AppColors.darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF7A0024),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.darkPrimary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF63001C),
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.darkPrimary,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF63001C),
      onTertiaryContainer: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.white,
      errorContainer: Colors.red.shade900,
      onErrorContainer: Colors.red.shade100,
      surface: AppColors.darkBackground,
      onSurface: Colors.white,
      // ignore: deprecated_member_use
      surfaceVariant: const Color(0xFF2A2C31),
      onSurfaceVariant: Colors.white70,
      outline: Colors.white24,
      outlineVariant: Colors.white12,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: AppColors.lightBackground,
      onInverseSurface: Colors.black87,
      inversePrimary: AppColors.lightPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'WallVagua',
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      textTheme: Typography.material2021().white.apply(fontFamily: 'WallVagua'),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBottomNavigation,
        selectedItemColor: AppColors.darkTextDefault,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.darkPrimary,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkFabBackground,
        foregroundColor: AppColors.darkFabIcon,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSearchBar,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
