import 'package:flutter/widgets.dart';

class AppVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Widget replacement;
  final bool maintainState;
  final bool maintainAnimation;
  final bool maintainSize;
  final bool maintainSemantics;
  final bool maintainInteractivity;

  const AppVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.replacement = const SizedBox.shrink(),
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!maintainState &&
        !maintainAnimation &&
        !maintainSize &&
        !maintainSemantics &&
        !maintainInteractivity) {
      return visible ? child : replacement;
    }

    return Visibility(
      visible: visible,
      maintainState: maintainState,
      maintainAnimation: maintainAnimation,
      maintainSize: maintainSize,
      maintainSemantics: maintainSemantics,
      maintainInteractivity: maintainInteractivity,
      replacement: replacement,
      child: child,
    );
  }
}

class AppVisible extends StatelessWidget {
  final Widget child;
  final bool visible;

  const AppVisible({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppVisibility(
      visible: visible,
      child: child,
    );
  }
}

class AppConditional extends StatelessWidget {
  final bool condition;
  final Widget whenTrue;
  final Widget whenFalse;

  const AppConditional({
    super.key,
    required this.condition,
    required this.whenTrue,
    required this.whenFalse,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? whenTrue : whenFalse;
  }
}