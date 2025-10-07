import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/category.dart';
import '../../providers/categories_provider.dart';
import '../../providers/layout_provider.dart';
import '../wallpapers/category_wallpaper_page.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(categoriesProvider),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const _EmptyState();
        }
        return layout.categoryLayout == CategoryLayout.list
            ? ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryListTile(category: category);
                },
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemCount: categories.length,
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryGridTile(category: category);
                },
              );
      },
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = theme.colorScheme.primary.withValues(alpha: 0.22);
    return GlowContainer(
      color: theme.cardColor.withValues(alpha: 0.94),
      glowColor: glowColor,
      blurRadius: 20,
      spreadRadius: 0.8,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: () => _openCategory(context, category),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: CachedNetworkImage(
              imageUrl: category.image,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.category_rounded),
            ),
          ),
        ),
        title: GlowText(
          category.name,
          style: theme.textTheme.titleMedium,
          glowColor: glowColor,
          blurRadius: 16,
        ),
        subtitle: Text('${category.totalWallpapers} wallpapers'),
        trailing: GlowIcon(
          Icons.chevron_right_rounded,
          color: theme.iconTheme.color,
          glowColor: glowColor,
          blurRadius: 12,
        ),
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = theme.colorScheme.primary.withValues(alpha: 0.26);
    return GlowContainer(
      color: theme.cardColor.withValues(alpha: 0.9),
      glowColor: glowColor,
      blurRadius: 28,
      spreadRadius: 1.2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openCategory(context, category),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.category_rounded, size: 48),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: GlowContainer(
                  color: Colors.black.withValues(alpha: 0.55),
                  glowColor: glowColor,
                  blurRadius: 18,
                  spreadRadius: 0.6,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowText(
                        category.name,
                        glowColor: glowColor,
                        blurRadius: 20,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${category.totalWallpapers} wallpapers',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No pudimos cargar las categorías', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('No hay categorías disponibles por el momento.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

void _openCategory(BuildContext context, Category category) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryWallpaperPage(category: category),
    ),
  );
}
