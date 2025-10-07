import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ModernShimmer extends StatefulWidget {
  const ModernShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final bool enabled;

  @override
  State<ModernShimmer> createState() => _ModernShimmerState();
}

class _ModernShimmerState extends State<ModernShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ModernShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = isDark ? AppColors.shimmerBase : AppColors.shimmerBase;
    final highlightColor = isDark ? AppColors.shimmerHighlight : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ModernShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class ShimmerWallpaperGrid extends StatelessWidget {
  const ShimmerWallpaperGrid({
    super.key,
    required this.columns,
    required this.aspectRatio,
    this.itemCount = 6,
  });

  final int columns;
  final double aspectRatio;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        return ShimmerCard(
          borderRadius: 20,
        );
      },
      itemCount: itemCount,
    );
  }
}

class ShimmerCategoryList extends StatelessWidget {
  const ShimmerCategoryList({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        return ShimmerCard(
          height: 80,
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ShimmerCard(
                  width: 64,
                  height: 64,
                  borderRadius: 16,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerCard(
                        height: 16,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 8),
                      ShimmerCard(
                        height: 12,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
                ShimmerCard(
                  width: 40,
                  height: 40,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemCount: itemCount,
    );
  }
}

class ShimmerCategoryGrid extends StatelessWidget {
  const ShimmerCategoryGrid({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        return ShimmerCard(
          borderRadius: 20,
        );
      },
      itemCount: itemCount,
    );
  }
}
