
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
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
    final iconColor = theme.iconTheme.color ?? theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final glowColor = primary.withValues(alpha: 0.35);

    return Scaffold(
      appBar: AppBar(
        title: GlowText(
          _titleForIndex(_currentIndex),
          style: theme.textTheme.titleLarge,
          glowColor: glowColor,
          blurRadius: 22,
        ),
        actions: [
          if (_currentIndex != 3) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlowContainer(
                color: Colors.transparent,
                glowColor: glowColor,
                blurRadius: 18,
                spreadRadius: 0.8,
                borderRadius: BorderRadius.circular(22),
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
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Buscar',
              icon: GlowIcon(
                Icons.search_rounded,
                color: iconColor,
                glowColor: glowColor,
                blurRadius: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
            ),
          ],
          IconButton(
            tooltip: 'Cambiar tema',
            icon: GlowIcon(
              theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              color: iconColor,
              glowColor: glowColor,
              blurRadius: 22,
            ),
            onPressed: themeController.toggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primary,
        unselectedItemColor: iconColor.withValues(alpha: 0.7),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_library_rounded),
            activeIcon: GlowIcon(
              Icons.photo_library_rounded,
              color: primary,
              glowColor: glowColor,
              blurRadius: 22,
            ),
            label: 'Wallpapers',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_rounded),
            activeIcon: GlowIcon(
              Icons.category_rounded,
              color: primary,
              glowColor: glowColor,
              blurRadius: 22,
            ),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_rounded),
            activeIcon: GlowIcon(
              Icons.favorite_rounded,
              color: primary,
              glowColor: glowColor,
              blurRadius: 22,
            ),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            activeIcon: GlowIcon(
              Icons.settings_rounded,
              color: primary,
              glowColor: glowColor,
              blurRadius: 22,
            ),
            label: 'Ajustes',
          ),
        ],
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
