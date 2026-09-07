import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool centerTitle;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBack,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? resolvedLeading = leading;

    if (resolvedLeading == null && showBackButton) {
      resolvedLeading = IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
        ),
        tooltip: 'Back',
      );
    }

    final titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign:
              centerTitle ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        if (subtitle != null &&
            subtitle!.trim().isNotEmpty) ...[
          const SizedBox(
            height: AppDimensions.spacing4,
          ),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign:
                centerTitle ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          if (resolvedLeading != null) ...[
            resolvedLeading,
            const SizedBox(
              width: AppDimensions.spacing4,
            ),
          ],
          if (centerTitle)
            Expanded(
              child: Center(
                child: titleWidget,
              ),
            )
          else
            Expanded(
              child: titleWidget,
            ),
          if (actions != null)
            ...actions!.map(
              (action) => Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spacing4,
                ),
                child: action,
              ),
            ),
        ],
      ),
    );
  }
}