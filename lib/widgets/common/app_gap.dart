import 'package:flutter/widgets.dart';

class AppGap extends StatelessWidget {
  final double size;
  final Axis axis;

  const AppGap({
    super.key,
    this.size = 8,
    this.axis = Axis.vertical,
  });

  const AppGap.vertical(
    this.size, {
    super.key,
  }) : axis = Axis.vertical;

  const AppGap.horizontal(
    this.size, {
    super.key,
  }) : axis = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.horizontal ? size : 0,
      height: axis == Axis.vertical ? size : 0,
    );
  }
}

class AppVerticalGap extends StatelessWidget {
  final double size;

  const AppVerticalGap(
    this.size, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
    );
  }
}

class AppHorizontalGap extends StatelessWidget {
  final double size;

  const AppHorizontalGap(
    this.size, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
    );
  }
}