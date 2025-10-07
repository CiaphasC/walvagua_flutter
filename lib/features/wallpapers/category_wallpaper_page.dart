import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/category.dart';
import '../../providers/wallpaper_feed_provider.dart';
import 'wallpaper_tab.dart';

class CategoryWallpaperPage extends StatelessWidget {
  const CategoryWallpaperPage({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: WallpaperTab(
        title: category.name,
        request: WallpaperFeedRequest(
          order: WallpaperOrder.recent,
          filter: WallpaperFilterType.wallpaper,
          category: category.id,
        ),
      ),
    );
  }
}
