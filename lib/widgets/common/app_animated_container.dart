import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppAnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final Color? color;
  final Color? hoverColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double scaleOnTap;

  const AppAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.onTap,
    this.color,
    this.hoverColor,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppDimensions.radius18),
    ),
    this.border,
    this.boxShadow,
    this.scaleOnTap = 0.98,
  });

  @override
  State<AppAnimatedContainer> createState() =>
      _AppAnimatedContainerState();
}

class _AppAnimatedContainerState
    extends State<AppAnimatedContainer> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onTap == null) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  void _handleTap() {
    if (widget.onTap == null) {
      return;
    }

    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _pressed
        ? (widget.hoverColor ??
            AppColors.cardGreen)
        : (widget.color ?? AppColors.surface);

    final scale = _pressed
        ? widget.scaleOnTap.clamp(0.90, 1.0)
        : 1.0;

    final content = AnimatedScale(
      scale: scale,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        width: double.infinity,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: widget.borderRadius,
          border: widget.border ??
              Border.all(
                color: AppColors.border,
                width: 1,
              ),
          boxShadow: widget.boxShadow ??
              [
                BoxShadow(
                  color: AppColors.shadow.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        _handleTap();
      },
      onTapCancel: () => _setPressed(false),
      child: content,
    );
  }
}