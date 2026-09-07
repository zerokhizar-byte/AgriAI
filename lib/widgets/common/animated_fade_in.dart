import 'package:flutter/material.dart';

class AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final double beginOpacity;

  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(
      milliseconds: 500,
    ),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.04),
    this.beginOpacity = 0,
  });

  @override
  State<AnimatedFadeIn> createState() =>
      _AnimatedFadeInState();
}

class _AnimatedFadeInState
    extends State<AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.beginOpacity,
      end: 1,
    ).animate(curvedAnimation);

    _positionAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }

    if (!mounted) {
      return;
    }

    await _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _positionAnimation,
            child: child,
          ),
        );
      },
    );
  }
}