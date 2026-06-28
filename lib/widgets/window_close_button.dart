import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/window_service.dart';

class WindowControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool compact;
  final Color? color;
  final double backgroundAlpha;
  final double iconAlpha;

  const WindowControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 34,
    this.iconSize = 18,
    this.compact = false,
    this.color,
    this.backgroundAlpha = 0.06,
    this.iconAlpha = 0.56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = color ?? cs.onSurface;
    final bgAlpha = compact ? backgroundAlpha + 0.02 : backgroundAlpha;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: baseColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(compact ? 7 : 10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: baseColor.withValues(alpha: bgAlpha + 0.06),
            splashColor: baseColor.withValues(alpha: bgAlpha + 0.08),
            child: Icon(
              icon,
              size: iconSize,
              color: baseColor.withValues(alpha: iconAlpha),
            ),
          ),
        ),
      ),
    );
  }
}

class WindowMinimizeButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool compact;

  const WindowMinimizeButton({
    super.key,
    this.size = 34,
    this.iconSize = 18,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: Icons.minimize_rounded,
      tooltip: context.l10n.minimize,
      onTap: WindowService.minimizeWindow,
      size: size,
      iconSize: iconSize,
      compact: compact,
    );
  }
}

class WindowMaximizeButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool compact;

  const WindowMaximizeButton({
    super.key,
    this.size = 34,
    this.iconSize = 17,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: Icons.crop_square_rounded,
      tooltip: context.l10n.maximizeRestore,
      onTap: WindowService.toggleMaximizeWindow,
      size: size,
      iconSize: iconSize,
      compact: compact,
    );
  }
}

class WindowCloseButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool compact;

  const WindowCloseButton({
    super.key,
    this.size = 34,
    this.iconSize = 18,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return WindowControlButton(
      icon: Icons.close_rounded,
      tooltip: context.l10n.closeApp,
      onTap: WindowService.closeWindow,
      size: size,
      iconSize: iconSize,
      compact: compact,
      color: cs.error,
      backgroundAlpha: 0.08,
      iconAlpha: 0.86,
    );
  }
}
