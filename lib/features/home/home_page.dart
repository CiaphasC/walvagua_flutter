import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_config_provider.dart';
import '../../providers/wallpaper_feed_provider.dart';
import '../wallpapers/wallpaper_tab.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);

    if (!appConfig.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final menus = appConfig.menus;

    return DefaultTabController(
      length: menus.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GlowContainer(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              glowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 1.4,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TabBar(
                isScrollable: true,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                tabs: [
                  for (final menu in menus)
                    Tab(
                      child: GlowText(
                        menu.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        glowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final menu in menus)
                  WallpaperTab(
                    title: menu.title,
                    request: WallpaperFeedRequest(
                      order: menu.order,
                      filter: menu.filter,
                      category: menu.category,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
