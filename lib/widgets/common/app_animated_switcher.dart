import 'package:flutter/material.dart';

class AppAnimatedSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;
  final AnimatedSwitcherLayoutBuilder? layoutBuilder;

  const AppAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
    this.transitionBuilder,
    this.layoutBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder:
          transitionBuilder ?? _defaultTransition,
      layoutBuilder:
          layoutBuilder ?? _defaultLayout,
      child: child,
    );
  }

  static Widget _defaultTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.97,
          end: 1.0,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  static Widget _defaultLayout(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...previousChildren,
        ?currentChild,
      ],
    );
  }
}

class AppFadeSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AppFadeSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(
      milliseconds: 250,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (
        child,
        animation,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

class AppSlideSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AppSlideSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(
      milliseconds: 300,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (
        child,
        animation,
      ) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}