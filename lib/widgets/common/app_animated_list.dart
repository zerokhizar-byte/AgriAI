import 'package:flutter/material.dart';

class AppAnimatedList extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final Duration duration;
  final Curve curve;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AppAnimatedList({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.padding = EdgeInsets.zero,
    this.spacing = 12,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
    this.shrinkWrap = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      separatorBuilder: (_, index) {
        return SizedBox(
          width: scrollDirection == Axis.horizontal
              ? spacing
              : 0,
          height: scrollDirection == Axis.vertical
              ? spacing
              : 0,
        );
      },
      itemBuilder: (context, index) {
        return _AnimatedListItem(
          key: ValueKey(index),
          index: index,
          duration: duration,
          curve: curve,
          child: children[index],
        );
      },
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const _AnimatedListItem({
    super.key,
    required this.index,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  State<_AnimatedListItem> createState() =>
      _AnimatedListItemState();
}

class _AnimatedListItemState
    extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(animation);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    _scale = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(animation);

    Future<void>.delayed(
      Duration(
        milliseconds: widget.index * 60,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}