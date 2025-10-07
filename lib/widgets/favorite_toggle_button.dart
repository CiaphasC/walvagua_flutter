import 'package:flutter/material.dart';

/// Boton reutilizable para alternar el estado de favorito manteniendo estilos consistentes.
class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.iconSize,
    this.padding,
    this.tooltip,
    this.backgroundShape,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final ShapeBorder? backgroundShape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final favoriteColor = activeColor ?? theme.colorScheme.primary;
    final neutralColor = inactiveColor ?? theme.colorScheme.onSurfaceVariant;

    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      padding: padding,
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? favoriteColor : neutralColor,
      ),
    );

    if (backgroundColor == null) {
      return button;
    }

    return Material(
      color: backgroundColor,
      shape: backgroundShape ?? const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: button,
    );
  }
}

