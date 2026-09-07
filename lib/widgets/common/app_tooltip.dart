import 'package:flutter/material.dart';

class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final String? richMessage;
  final bool preferBelow;
  final double verticalOffset;
  final Duration waitDuration;
  final Duration showDuration;

  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.richMessage,
    this.preferBelow = true,
    this.verticalOffset = 12,
    this.waitDuration = const Duration(
      milliseconds: 400,
    ),
    this.showDuration = const Duration(
      seconds: 3,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      verticalOffset: verticalOffset,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: child,
    );
  }
}

class AppIconTooltip extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;

  const AppIconTooltip({
    super.key,
    required this.message,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}