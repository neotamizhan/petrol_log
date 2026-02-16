import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final bool enableBlur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.color,
    this.border,
    this.boxShadow,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final panelColor = color ??
        (isDark
            ? AppColors.surfaceDark.withOpacity(0.75)
            : AppColors.surfaceLight.withOpacity(0.9));

    final panelBorder = border ??
        Border.all(
          color: isDark
              ? AppColors.outlineDark.withOpacity(0.6)
              : AppColors.outlineLight,
        );

    final panelShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: borderRadius,
        border: panelBorder,
        boxShadow: panelShadow,
      ),
      child: child,
    );

    if (!enableBlur) return content;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}
