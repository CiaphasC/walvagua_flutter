import 'package:flutter/material.dart';
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
          TabBar(
            isScrollable: true,
            tabs: [
              for (final menu in menus)
                Tab(
                  text: menu.title,
                ),
            ],
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
