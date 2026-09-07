import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

class AppPagePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppPagePadding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacing16,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}