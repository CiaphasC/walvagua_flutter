import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Paleta moderna con gradientes y colores más vibrantes
  static const lightPrimary = Color(0xFF6C5CE7); // Púrpura moderno
  static const lightPrimaryVariant = Color(0xFF5A4FCF);
  static const lightAccent = Color(0xFFFF6B9D); // Rosa vibrante
  static const lightSecondary = Color(0xFFFFD93D); // Amarillo dorado
  static const lightTertiary = Color(0xFF74B9FF); // Azul cielo
  
  static const lightBackground = Color(0xFFFAFBFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF8F9FA);
  static const lightBottomNavigation = Color(0xFFFFFFFF);
  static const lightSearchBar = Color(0xFFF1F3F4);
  static const lightTextDefault = Color(0xFF2D3436);
  static const lightTextSecondary = Color(0xFF636E72);
  static const lightFabBackground = Color(0xFFFFFFFF);
  static const lightFabIcon = Color(0xFF6C5CE7);

  // Colores oscuros más sofisticados
  static const darkPrimary = Color(0xFF7B68EE);
  static const darkPrimaryVariant = Color(0xFF6A5ACD);
  static const darkAccent = Color(0xFFFF6B9D);
  static const darkSecondary = Color(0xFFFFD93D);
  static const darkTertiary = Color(0xFF74B9FF);
  
  static const darkBackground = Color(0xFF0F0F23);
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkSurfaceVariant = Color(0xFF16213E);
  static const darkBottomNavigation = Color(0xFF1A1A2E);
  static const darkSearchBar = Color(0xFF16213E);
  static const darkTextDefault = Color(0xFFE94560);
  static const darkTextSecondary = Color(0xFFB2BEC3);
  static const darkFabBackground = Color(0xFF1A1A2E);
  static const darkFabIcon = Color(0xFFE94560);

  // Colores de estado y utilidades
  static const shimmerBase = Color(0xFFE2E8F0);
  static const shimmerHighlight = Color(0xFFF7FAFC);
  static const greySoft = Color(0xFFE2E8F0);
  static const separator = Color(0xFFE2E8F0);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFFD93D);
  static const error = Color(0xFFE17055);
  static const info = Color(0xFF74B9FF);

  // Gradientes modernos
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF5A4FCF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8A95)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFBFC), Color(0xFFF1F3F4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      surfaceTint: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightTextDefault,
      secondaryContainer: AppColors.lightSecondary,
      onSecondaryContainer: AppColors.lightTextDefault,
      tertiary: AppColors.lightTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.lightTertiary,
      onTertiaryContainer: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0x1AE17055), // AppColors.error.withOpacity(0.1)
      onErrorContainer: AppColors.error,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextDefault,
      surfaceVariant: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.greySoft,
      outlineVariant: AppColors.separator,
      shadow: const Color(0x14000000), // Colors.black.withOpacity(0.08)
      scrim: const Color(0x66000000), // Colors.black.withOpacity(0.4)
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.lightPrimary,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.lightPrimary.withAlpha((0.14 * 255).round()),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.lightPrimary : AppColors.lightTextDefault.withAlpha((0.7 * 255).round()));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.lightPrimary : AppColors.lightTextDefault.withAlpha((0.7 * 255).round()),
            fontWeight: FontWeight.w600,
          );
        }),
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
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      surfaceTint: AppColors.darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.darkPrimaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkTextDefault,
      secondaryContainer: AppColors.darkSecondary,
      onSecondaryContainer: AppColors.darkTextDefault,
      tertiary: AppColors.darkTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.darkTertiary,
      onTertiaryContainer: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0x33E17055), // AppColors.error.withOpacity(0.2)
      onErrorContainer: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: Colors.white,
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: const Color(0x4DB2BEC3), // AppColors.darkTextSecondary.withOpacity(0.3)
      outlineVariant: const Color(0x1AB2BEC3), // AppColors.darkTextSecondary.withOpacity(0.1)
      shadow: const Color(0x4D000000), // Colors.black.withOpacity(0.3)
      scrim: const Color(0x99000000), // Colors.black.withOpacity(0.6)
      inverseSurface: AppColors.lightBackground,
      onInverseSurface: AppColors.lightTextDefault,
      inversePrimary: AppColors.darkPrimary,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.darkPrimary.withAlpha((0.18 * 255).round()),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? Colors.white : Colors.white70);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          );
        }),
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
