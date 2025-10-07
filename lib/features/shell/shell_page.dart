import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        title: Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
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
              Expanded(
                child: Center(
                  child: Text(
                    _titleForIndex(_currentIndex),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (_currentIndex != 3) {
                        setState(() => _currentIndex = 3);
                      }
                    },
                    child: Ink.image(
                      image: const AssetImage('assets/images/app_icon_circle.webp'),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          navHorizontalPadding,
          0,
          navHorizontalPadding,
          navBottomPadding,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(isCompact ? 0 : 20)),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: navBlur, sigmaY: navBlur),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      navHighlight,
                      navGlassColor,
                    ],
                  ),
                  border: Border(
                    top: BorderSide(color: navBorderColor),
                  ),
                  boxShadow: [
                    BoxShadow(color: navShadowColor, blurRadius: 8, offset: const Offset(0, -1)),
                  ],
                ),
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
                      icon: const Icon(Icons.photo_library_outlined),
                      selectedIcon: Icon(Icons.photo_library_rounded, color: primary),
                      label: 'Wallpapers',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.category_outlined),
                      selectedIcon: Icon(Icons.category_rounded, color: primary),
                      label: 'Categorías',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded, color: primary),
                      label: 'Favoritos',
                    ),
                    NavigationDestination(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      selectedIcon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: primary,
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

