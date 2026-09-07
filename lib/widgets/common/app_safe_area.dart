import 'package:flutter/material.dart';

class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final Color? backgroundColor;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );

    if (backgroundColor == null) {
      return content;
    }

    return ColoredBox(
      color: backgroundColor!,
      child: content,
    );
  }
}