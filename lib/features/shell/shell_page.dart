import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../categories/categories_page.dart';
import '../favorites/favorites_page.dart';
import '../home/home_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    CategoriesPage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final isCompact = width < 600;
    final isDark = theme.brightness == Brightness.dark;

    final navGlassColor = theme.colorScheme.surface.withValues(
      alpha: isDark
          ? (isCompact ? 0.36 : 0.4)
          : (isCompact ? 0.58 : 0.54),
    );
    final navHighlight = Colors.white.withValues(
      alpha: isDark ? (isCompact ? 0.02 : 0.04) : (isCompact ? 0.08 : 0.1),
    );
    final navBorderColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? (isCompact ? 0.08 : 0.1) : (isCompact ? 0.05 : 0.07),
    );
    final navShadowColor = Colors.black.withValues(alpha: isDark ? 0.16 : 0.1);
    final navBlur = isCompact ? 8.0 : 12.0;
    final navHeight = isCompact ? 64.0 : 72.0;
    final navHorizontalPadding = isCompact ? 0.0 : 24.0;
    final navBottomPadding = mediaQuery.padding.bottom + (isCompact ? 8.0 : 16.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            // AppBar moderno con glassmorphism
            Container(
              height: 72,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.surface.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      // Botón de búsqueda
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          tooltip: 'Buscar',
                          icon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SearchPage()),
                            );
                          },
                        ),
                      ),
                      // Título centrado
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _titleForIndex(_currentIndex),
                              key: ValueKey(_currentIndex),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Botón de configuración
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                          child: IconButton(
                            tooltip: 'Configuración',
                            icon: Icon(
                              Icons.settings_rounded,
                              color: theme.colorScheme.secondary,
                            ),
                            onPressed: () {
                              if (_currentIndex != 3) {
                                setState(() => _currentIndex = 3);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Contenido principal con animación
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          navHorizontalPadding + 16,
          0,
          navHorizontalPadding + 16,
          navBottomPadding + 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surface.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: NavigationBar(
                  height: navHeight,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: primary.withValues(alpha: isCompact ? 0.14 : 0.17),
                  selectedIndex: _currentIndex,
                  labelBehavior: isCompact
                      ? NavigationDestinationLabelBehavior.alwaysShow
                      : NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    if (index == 3) {
                      themeController.toggleTheme();
                      return;
                    }
                    setState(() => _currentIndex = index);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == 0 ? primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: _currentIndex == 0 ? primary : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white),
                      ),
                      label: 'Wallpapers',
                    ),
                    NavigationDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == 1 ? primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: _currentIndex == 1 ? primary : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.category_rounded, color: Colors.white),
                      ),
                      label: 'Categorías',
                    ),
                    NavigationDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == 2 ? primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: _currentIndex == 2 ? primary : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.lightAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white),
                      ),
                      label: 'Favoritos',
                    ),
                    NavigationDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == 3 ? primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: _currentIndex == 3 ? primary : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.lightSecondary, AppColors.lightSecondary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.lightSecondary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                      ),
                      label: 'Tema',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'WallVagua';
      case 1:
        return 'Categorías';
      case 2:
        return 'Favoritos';
      case 3:
        return 'Ajustes';
      default:
        return 'WallVagua';
    }
  }
}

