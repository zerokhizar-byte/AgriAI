import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final ScrollPhysics? physics;
  final Color? color;
  final Color? backgroundColor;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.physics,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor:
          backgroundColor ?? AppColors.surface,
      strokeWidth: 2.5,
      displacement: 42,
      edgeOffset: 0,
      child: child,
    );
  }
}

class AppRefreshableList extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AppRefreshableList({
    super.key,
    required this.children,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    this.spacing = 12,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: padding,
        physics: physics ??
            const AlwaysScrollableScrollPhysics(),
        shrinkWrap: shrinkWrap,
        itemCount: children.length,
        separatorBuilder: (_, index) {
          return SizedBox(
            height: spacing,
          );
        },
        itemBuilder: (context, index) {
          return children[index];
        },
      ),
    );
  }
}

class AppRefreshableScrollView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const AppRefreshableScrollView({
    super.key,
    required this.children,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: physics ??
            const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}