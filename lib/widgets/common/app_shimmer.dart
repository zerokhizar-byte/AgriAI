import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppShimmer({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius = AppDimensions.radius12,
    this.margin,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ),
    )..repeat();
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
      builder: (context, child) {
        final value = _controller.value;

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              widget.borderRadius,
            ),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + value * 3, 0),
              end: Alignment(-0.5 + value * 3, 0),
              colors: const [
                AppColors.background,
                AppColors.cardGreen,
                AppColors.background,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppShimmerBox({
    super.key,
    this.width,
    this.height = 100,
    this.borderRadius = AppDimensions.radius16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class AppShimmerText extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const AppShimmerText({
    super.key,
    this.width = 140,
    this.height = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      width: width,
      height: height,
      borderRadius: 7,
      margin: margin,
    );
  }
}

class AppShimmerCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const AppShimmerCircle({
    super.key,
    this.size = 48,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }
}

class AppShimmerCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const AppShimmerCard({
    super.key,
    this.height = 150,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(
        AppDimensions.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppShimmerCircle(
                size: 44,
              ),
              const SizedBox(
                width: AppDimensions.spacing12,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    AppShimmerText(
                      width: 120,
                      height: 14,
                    ),
                    AppShimmerText(
                      width: 80,
                      height: 10,
                      margin: EdgeInsets.only(
                        top: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppDimensions.spacing18,
          ),
          const AppShimmerText(
            width: double.infinity,
            height: 12,
          ),
          const AppShimmerText(
            width: 180,
            height: 12,
            margin: EdgeInsets.only(
              top: 8,
            ),
          ),
        ],
      ),
    );
  }
}