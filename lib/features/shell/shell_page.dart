
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
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        title: Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
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
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            selectedIndex: _currentIndex,
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
                icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                selectedIcon: Icon(
                  theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
                  color: primary,
                ),
                label: 'Tema',
              ),
            ],
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
